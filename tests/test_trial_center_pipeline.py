from __future__ import annotations

from unittest import mock

from trial_center_pipeline import (
    GuardrailConfig,
    GuardianPromptForge,
    PromptSanitizer,
    SanitizationConfig,
)


def _mock_guardrail_response(score: float = 0.7, outcome: str = "accepted"):
    return {
        "messages": [
            {
                "id": "1",
                "outcome": outcome,
                "score": score,
                "processors": [
                    {"name": "semantic", "score": score, "explanation": "sensitive"}
                ],
            }
        ]
    }


@mock.patch("trial_center_pipeline.protegrity.configure")
@mock.patch("trial_center_pipeline.protegrity.discover", return_value={"PERSON": []})
@mock.patch(
    "trial_center_pipeline.protegrity.find_and_unprotect"
)
@mock.patch(
    "trial_center_pipeline.protegrity.find_and_protect",
    side_effect=RuntimeError("protection unavailable"),
)
@mock.patch(
    "trial_center_pipeline.protegrity.find_and_redact",
    return_value="[REDACTED]",
)
@mock.patch(
    "trial_center_pipeline.requests.post",
    return_value=mock.Mock(
        raise_for_status=mock.Mock(),
        json=mock.Mock(return_value=_mock_guardrail_response()),
    ),
)
def test_trial_center_pipeline_falls_back_to_redaction(
    mock_post,
    mock_redact,
    mock_protect,
    mock_unprotect,
    mock_discover,
    mock_configure,
):
    forge = GuardianPromptForge(
        guardrail_config=GuardrailConfig(rejection_threshold=0.6),
        sanitization_config=SanitizationConfig(method="protect"),
    )

    report = forge.process_prompt("Sensitive prompt with PII")

    assert report.guardrail.outcome == "accepted"
    assert report.sanitization.method_used == "redact"
    assert report.sanitization.sanitized_prompt == "[REDACTED]"
    assert report.sanitization.unprotected_prompt is None
    mock_post.assert_called_once()
    mock_redact.assert_called_once()
    mock_unprotect.assert_not_called()


@mock.patch("trial_center_pipeline.protegrity.configure")
@mock.patch("trial_center_pipeline.protegrity.discover", return_value={})
@mock.patch(
    "trial_center_pipeline.protegrity.find_and_redact",
    return_value="Sentence one. Sentence two.",
)
@mock.patch(
    "trial_center_pipeline.requests.post",
    return_value=mock.Mock(
        raise_for_status=mock.Mock(),
        json=mock.Mock(return_value=_mock_guardrail_response(score=0.2)),
    ),
)
def test_trial_center_pipeline_accepts_low_risk_prompt(
    mock_post,
    mock_redact,
    mock_discover,
    mock_configure,
):
    forge = GuardianPromptForge(
        guardrail_config=GuardrailConfig(rejection_threshold=0.6),
        sanitization_config=SanitizationConfig(method="redact"),
    )

    report = forge.process_prompt("Sentence one. Sentence two.")

    assert report.guardrail.outcome == "accepted"
    assert report.sanitization.sanitized_prompt == "Sentence one. Sentence two."
    assert report.sanitization.unprotected_prompt is None


@mock.patch("trial_center_pipeline.protegrity.configure")
@mock.patch("trial_center_pipeline.protegrity.discover", return_value={})
@mock.patch(
    "trial_center_pipeline.protegrity.find_and_redact",
    return_value="Sanitized",
)
@mock.patch(
    "trial_center_pipeline.requests.post",
    return_value=mock.Mock(
        raise_for_status=mock.Mock(),
        json=mock.Mock(return_value=_mock_guardrail_response(score=0.49, outcome="approved")),
    ),
)
def test_trial_center_pipeline_preserves_service_outcome(
    mock_post,
    mock_redact,
    mock_discover,
    mock_configure,
):
    forge = GuardianPromptForge(
        guardrail_config=GuardrailConfig(rejection_threshold=0.3),
        sanitization_config=SanitizationConfig(method="redact"),
    )

    report = forge.process_prompt("Prompt")

    assert report.guardrail.outcome == "approved"
    assert report.sanitization.sanitized_prompt == "Sanitized"
    assert report.sanitization.unprotected_prompt is None


@mock.patch("trial_center_pipeline.protegrity.configure")
@mock.patch("trial_center_pipeline.protegrity.discover", return_value={})
@mock.patch(
    "trial_center_pipeline.protegrity.find_and_unprotect",
    return_value="Restored prompt",
)
@mock.patch(
    "trial_center_pipeline.protegrity.find_and_protect",
    return_value="[TOKEN]Restored prompt[/TOKEN]",
)
@mock.patch(
    "trial_center_pipeline.protegrity.find_and_redact"
)
@mock.patch(
    "trial_center_pipeline.requests.post",
    return_value=mock.Mock(
        raise_for_status=mock.Mock(),
        json=mock.Mock(return_value=_mock_guardrail_response(score=0.2)),
    ),
)
def test_trial_center_pipeline_handles_unprotect(
    mock_post,
    mock_redact,
    mock_protect,
    mock_unprotect,
    mock_discover,
    mock_configure,
):
    forge = GuardianPromptForge(
        guardrail_config=GuardrailConfig(rejection_threshold=0.6),
        sanitization_config=SanitizationConfig(method="protect"),
    )

    report = forge.process_prompt("Prompt")

    assert report.guardrail.outcome == "accepted"
    assert report.sanitization.method_used == "protect"
    assert report.sanitization.raw_sanitized_prompt == "[TOKEN]Restored prompt[/TOKEN]"
    assert report.sanitization.display_prompt == "[TOKEN]***[/TOKEN]"
    assert report.sanitization.unprotected_prompt == "Restored prompt"
    mock_unprotect.assert_called_once_with("[TOKEN]Restored prompt[/TOKEN]")


@mock.patch("trial_center_pipeline.protegrity.configure")
@mock.patch(
    "trial_center_pipeline.protegrity.discover",
    return_value={},
)
@mock.patch(
    "trial_center_pipeline.protegrity.find_and_redact",
    side_effect=["[PERSON] [PERSON]", "[PHONE]"],
)
def test_prompt_sanitizer_redacts_each_non_empty_line(
    mock_redact,
    mock_discover,
    mock_configure,
):
    sanitizer = PromptSanitizer(SanitizationConfig(method="redact"))
    prompt = "Names line\n\nPhone line"

    result = sanitizer.sanitize(prompt)

    assert result.sanitized_prompt == "[PERSON] [PERSON]\n\n[PHONE]"
    assert mock_redact.call_count == 2
    mock_redact.assert_any_call("Names line")
    mock_redact.assert_any_call("Phone line")


@mock.patch("trial_center_pipeline.protegrity.configure")
@mock.patch(
    "trial_center_pipeline.protegrity.discover",
    return_value={"PERSON|COMPANY_NAME": [{"location": {"start_index": 0, "end_index": 4}}]},
)
@mock.patch(
    "trial_center_pipeline.protegrity.find_and_redact",
    return_value="[PERSON]",
)
def test_prompt_sanitizer_extends_composite_entity_mapping(
    mock_redact,
    mock_discover,
    mock_configure,
):
    sanitizer = PromptSanitizer(SanitizationConfig(method="redact"))
    result = sanitizer.sanitize("Composite label prompt")

    named_maps = [
        kwargs["named_entity_map"]
        for _, kwargs in mock_configure.call_args_list
        if "named_entity_map" in kwargs
    ]

    assert any(mapping.get("PERSON|COMPANY_NAME") == "PERSON" for mapping in named_maps)
    assert "PERSON|COMPANY_NAME" not in result.discovery_entities
    assert result.discovery_entities.get("PERSON")
