#
# METADATA
# title: SLSA - Provenance - Available
# description: >-
#   The SLSA Provenance Available requirement states the following:
#
#   "The provenance is available to the consumer in a format that the consumer accepts. The
#   format SHOULD be in-toto SLSA Provenance, but another format MAY be used if both producer
#   and consumer agree and it meets all the other requirements."
#
#   This package only accepts the in-toto SLSA Provenance format.
#
package release.slsa_provenance_available

import rego.v1

import data.lib

# METADATA
# title: Expected attestation predicate type found
# description: >-
#   Verify that the predicateType field of the attestation indicates the in-toto SLSA Provenance
#   format was used to attest the PipelineRun.
# custom:
#   short_name: attestation_predicate_type_accepted
#   failure_msg: Attestation predicate type %q is not an expected type (%s)
#   solution: >-
#     The predicate type field in the attestation does not match the 'allowed_predicate_types' field.
#     This field is set in the xref:ec-cli:ROOT:configuration.adoc#_data_sources[data sources].
#   collections:
#   - minimal
#   - slsa3
#   - redhat
#   depends_on:
#   - attestation_type.known_attestation_type
#
deny contains result if {
	some att in lib.pipelinerun_attestations
	allowed_predicate_types := lib.rule_data(_rule_data_key)
	not att.statement.predicateType in allowed_predicate_types
	result := lib.result_helper(
		rego.metadata.chain(),
		[att.statement.predicateType, concat(", ", allowed_predicate_types)],
	)
}

# METADATA
# title: Allowed predicate types provided
# description: >-
#   Confirm the `allowed_predicate_types` rule data was provided, since it is required by the policy
#   rules in this package.
# custom:
#   short_name: allowed_predicate_types_provided
#   failure_msg: "%s"
#   collections:
#   - minimal
#   - slsa3
#   - redhat
#   - policy_data
#
deny contains result if {
	some error in _rule_data_errors
	result := lib.result_helper(rego.metadata.chain(), [error])
}

# Verify allowed_predicate_types is a non-empty list of strings
_rule_data_errors contains msg if {
	# match_schema expects either a marshaled JSON resource (String) or an Object. It doesn't
	# handle an Array directly.
	value := json.marshal(lib.rule_data(_rule_data_key))
	some violation in json.match_schema(
		value,
		{
			"$schema": "http://json-schema.org/draft-07/schema#",
			"type": "array",
			"items": {"type": "string"},
			"uniqueItems": true,
			"minItems": 1,
		},
	)[1]
	msg := sprintf("Rule data %s has unexpected format: %s", [_rule_data_key, violation.error])
}

_rule_data_key := "allowed_predicate_types"
