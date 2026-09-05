import argparse
import json
import sys
from pathlib import Path


def fail(message):
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_blueprint(path):
    try:
        with path.open("r", encoding="utf-8-sig") as handle:
            data = json.load(handle)
    except Exception as exc:
        fail(f"Unable to load canonical blueprint: {exc}")

    if not isinstance(data, dict):
        fail("Canonical blueprint root must be an object.")

    if data.get("status") != "CANONICAL":
        fail("Canonical blueprint status must be CANONICAL.")

    return data


def validate_blueprint(data):
    domains = data.get("domains")

    if not isinstance(domains, list):
        fail("Canonical blueprint domains must be a list.")

    if len(domains) != 7:
        fail(
            f"Canonical blueprint must contain exactly 7 domains. "
            f"Found {len(domains)}."
        )

    expected_domain_ids = [f"d{i:02d}" for i in range(1, 8)]

    actual_domain_ids = [
        domain.get("domain_id")
        for domain in domains
        if isinstance(domain, dict)
    ]

    if actual_domain_ids != expected_domain_ids:
        fail(
            "Canonical domain IDs are invalid. "
            f"Expected {expected_domain_ids}, found {actual_domain_ids}."
        )

    all_competencies = []

    for expected_number, domain in enumerate(domains, start=1):
        if not isinstance(domain, dict):
            fail(
                f"Domain {expected_number} is not a valid object."
            )

        domain_id = domain.get("domain_id")
        domain_number = domain.get("domain_number")
        domain_name = domain.get("name")
        weight = domain.get("weight_percent")
        competencies = domain.get("competencies")

        if domain_number != expected_number:
            fail(
                f"{domain_id}: expected domain_number "
                f"{expected_number}, found {domain_number}."
            )

        if not isinstance(domain_name, str) or not domain_name.strip():
            fail(f"{domain_id}: domain name is missing or empty.")

        if not isinstance(weight, (int, float)) or weight <= 0:
            fail(f"{domain_id}: weight_percent must be positive.")

        if not isinstance(competencies, list) or not competencies:
            fail(f"{domain_id}: competencies must be a non-empty list.")

        expected_competency_numbers = list(range(1, len(competencies) + 1))

        actual_competency_numbers = [
            competency.get("number")
            for competency in competencies
            if isinstance(competency, dict)
        ]

        if actual_competency_numbers != expected_competency_numbers:
            fail(
                f"{domain_id}: competency numbering is not sequential. "
                f"Expected {expected_competency_numbers}, "
                f"found {actual_competency_numbers}."
            )

        for competency in competencies:
            if not isinstance(competency, dict):
                fail(f"{domain_id}: competency record is malformed.")

            competency_id = competency.get("competency_id")
            number = competency.get("number")
            statement = competency.get("statement")

            expected_id = f"{domain_id}_c{number:02d}"

            if competency_id != expected_id:
                fail(
                    f"{domain_id}: competency ID mismatch. "
                    f"Expected {expected_id}, found {competency_id}."
                )

            if not isinstance(statement, str) or not statement.strip():
                fail(
                    f"{competency_id}: competency statement is missing "
                    "or empty."
                )

            all_competencies.append(competency)

    if len(all_competencies) != 47:
        fail(
            "Canonical blueprint must contain exactly 47 competencies. "
            f"Found {len(all_competencies)}."
        )

    competency_ids = [
        competency["competency_id"]
        for competency in all_competencies
    ]

    if len(set(competency_ids)) != len(competency_ids):
        fail("Duplicate canonical competency IDs detected.")

    weight_total = sum(
        domain["weight_percent"]
        for domain in domains
    )

    if weight_total != 100:
        fail(
            f"Canonical domain weights must total 100. "
            f"Found {weight_total}."
        )

    return domains


def dart_string(value):
    return (
        "'"
        + str(value)
        .replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        + "'"
    )


def generate_dart(domains):
    lines = []

    lines.extend([
        "// GENERATED FILE. DO NOT EDIT BY HAND.",
        "//",
        "// Authoritative source:",
        "// docs/source_pipeline/CSP11_canonical_blueprint.json",
        "//",
        "// Generated deterministically by:",
        "// tools/source_pipeline/generate_csp11_dart_registry.py",
        "",
        "class Csp11Competency {",
        "  final String id;",
        "  final String domainId;",
        "  final int number;",
        "  final String statement;",
        "",
        "  const Csp11Competency({",
        "    required this.id,",
        "    required this.domainId,",
        "    required this.number,",
        "    required this.statement,",
        "  });",
        "}",
        "",
        "class Csp11Domain {",
        "  final String id;",
        "  final int number;",
        "  final String title;",
        "  final int weightPercent;",
        "  final List<Csp11Competency> competencies;",
        "",
        "  const Csp11Domain({",
        "    required this.id,",
        "    required this.number,",
        "    required this.title,",
        "    required this.weightPercent,",
        "    required this.competencies,",
        "  });",
        "}",
        "",
        "const List<Csp11Domain> csp11Domains = <Csp11Domain>[",
    ])

    for domain in domains:
        lines.extend([
            "  Csp11Domain(",
            f"    id: {dart_string(domain['domain_id'])},",
            f"    number: {domain['domain_number']},",
            f"    title: {dart_string(domain['name'])},",
            f"    weightPercent: {int(domain['weight_percent'])},",
            "    competencies: <Csp11Competency>[",
        ])

        for competency in domain["competencies"]:
            lines.extend([
                "      Csp11Competency(",
                f"        id: {dart_string(competency['competency_id'])},",
                f"        domainId: {dart_string(f"domain_{domain['domain_number']:02d}")},",
                f"        number: {competency['number']},",
                "        statement:",
                f"            {dart_string(competency['statement'])},",
                "      ),",
            ])

        lines.extend([
            "    ],",
            "  ),",
        ])

    lines.extend([
        "];",
        "",
        "Csp11Domain? domainForId(String id) {",
        "  for (final domain in csp11Domains) {",
        "    if (domain.id == id) {",
        "      return domain;",
        "    }",
        "  }",
        "",
        "  return null;",
        "}",
        "",
        "Csp11Domain? domainForContentId(String domainId) {",
        "  final normalized = domainId.trim().toLowerCase();",
        "",
        "  for (final domain in csp11Domains) {",
        "    if (domain.id.toLowerCase() == normalized ||",
        "        'domain_${domain.number.toString().padLeft(2, '0')}' == normalized ||",
        "        'domain${domain.number}' == normalized ||",
        "        domain.number.toString() == normalized.replaceAll('domain', '')) {",
        "      return domain;",
        "    }",
        "  }",
        "",
        "  return null;",
        "}",
        "",
        "Csp11Domain domainForNumber(int number) {",
        "  if (number < 1 || number > csp11Domains.length) {",
        "    throw ArgumentError.value(",
        "      number,",
        "      'number',",
        "      'CSP11 domain number must be 1-7.',",
        "    );",
        "  }",
        "",
        "  return csp11Domains[number - 1];",
        "}",
        "",
        "Csp11Competency? competencyForId(String id) {",
        "  final normalized = id.trim().toLowerCase();",
        "",
        "  for (final domain in csp11Domains) {",
        "    for (final competency in domain.competencies) {",
        "      if (competency.id.toLowerCase() == normalized) {",
        "        return competency;",
        "      }",
        "    }",
        "  }",
        "",
        "  return null;",
        "}",
        "",
        "List<Csp11Competency> competenciesForDomain(String domainId) {",
        "  final domain = domainForContentId(domainId);",
        "",
        "  if (domain == null) {",
        "    return const <Csp11Competency>[];",
        "  }",
        "",
        "  return domain.competencies;",
        "}",
        "",
        "Csp11Competency? competencyForDomainAndNumber(",
        "  String domainId,",
        "  int competencyNumber,",
        ") {",
        "  final domain = domainForContentId(domainId);",
        "",
        "  if (domain == null) {",
        "    return null;",
        "  }",
        "",
        "  for (final competency in domain.competencies) {",
        "    if (competency.number == competencyNumber) {",
        "      return competency;",
        "    }",
        "  }",
        "",
        "  return null;",
        "}",
        "",
    ])

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Generate the CSP11 Dart competency registry "
                    "from the canonical blueprint."
    )

    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)

    args = parser.parse_args()

    data = load_blueprint(args.input)
    domains = validate_blueprint(data)
    output = generate_dart(domains)

    args.output.parent.mkdir(parents=True, exist_ok=True)

    args.output.write_text(
        output,
        encoding="utf-8",
        newline="\n",
    )

    competency_count = sum(
        len(domain["competencies"])
        for domain in domains
    )

    print("===== L23E-1B DETERMINISTIC DART REGISTRY GENERATION =====")
    print(f"Domains: {len(domains)}")
    print(f"Competencies: {competency_count}")
    print("Canonical source: CSP11_canonical_blueprint.json")
    print("Deterministic output: YES")
    print(f"Output: {args.output}")


if __name__ == "__main__":
    main()
