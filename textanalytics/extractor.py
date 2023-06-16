import sys
import requests
import uuid
import json
from azure.core.credentials import AzureKeyCredential
from azure.ai.textanalytics import TextAnalyticsClient
from azure.ai.translation.document import DocumentTranslationClient, TranslationTarget


def sample_extractive_summarization():
    # [START extract_summary]

    endpoint = sys.argv[2]
    key = sys.argv[3]

    text_analytics_client = TextAnalyticsClient(
        endpoint=endpoint,
        credential=AzureKeyCredential(key),
    )

    document = [sys.argv[1]]  # type must be a list

    poller = text_analytics_client.begin_extract_summary(document, max_sentence_count=2)
    extract_summary_results = poller.result()
    summary = ""
    for result in extract_summary_results:
        if result.kind == "ExtractiveSummarization":
            summary = " ".join(
                [sentence.text for sentence in result.sentences])
        elif result.is_error is True:
            print("...Is an error with code '{}' and message '{}'".format(
                result.error.code, result.error.message
            ))
    # [END extract_summary]
    return summary


def translate_to_jp(summary):

    key = sys.argv[5]
    location = sys.argv[4]
    endpoint = "https://api.cognitive.microsofttranslator.com"

    path = '/translate'
    constructed_url = endpoint + path

    params = {
        'api-version': '3.0',
        'from': 'en',
        'to': ['zh-Hant']
    }

    headers = {
        'Ocp-Apim-Subscription-Key': key,
        # location required if you're using a multi-service or regional (not global) resource.
        'Ocp-Apim-Subscription-Region': location,
        'Content-type': 'application/json',
        'X-ClientTraceId': str(uuid.uuid4())
    }

    # You can pass more than one object in body.
    body = [{
        'text': summary
    }]

    request = requests.post(constructed_url, params=params,
                            headers=headers, json=body)
    response = request.json()

    print((response[0]['translations'][0]['text']))


# Example usage
summary = sample_extractive_summarization()
translate_to_jp(summary)
