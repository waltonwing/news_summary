# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------

"""
FILE: sample_extract_summary.py

DESCRIPTION:
    This sample demonstrates how to submit text documents for extractive text summarization.
    Extractive summarization is available as an action type through the begin_analyze_actions API.

USAGE:
    python sample_extract_summary.py

    Set the environment variables with your own values before running the sample:
    1) AZURE_LANGUAGE_ENDPOINT - the endpoint to your Language resource.
    2) AZURE_LANGUAGE_KEY - your Language subscription key
"""


def sample_extractive_summarization():
    # [START extract_summary]
    import os
    from azure.core.credentials import AzureKeyCredential
    from azure.ai.textanalytics import TextAnalyticsClient
    from azure.ai.translation.text import TextTranslationClient, TranslatorCredential

    text_analytics_endpoint = os.environ["AZURE_LANGUAGE_ENDPOINT"]
    text_analytics_key = os.environ["AZURE_LANGUAGE_KEY"]
    translator_endpoint = os.environ["TRANSLATOR_ENDPOINT"]
    translator_key = os.environ["TRANSLATOR_KEY"]

    text_analytics_client = TextAnalyticsClient(
        endpoint=text_analytics_endpoint,
        credential=AzureKeyCredential(text_analytics_key),
    )

    credential = TranslatorCredential(translator_key, "eastus")
    translator_client = TextTranslationClient(
        endpoint=translator_endpoint,
        credential=credential,
    )

    path_to_sample_document = os.path.abspath(
        os.path.join(
            os.path.abspath(__file__),
            "..",
            "./text_samples/custom_wsj_news.txt",
        )
    )

    with open(path_to_sample_document, encoding='utf-8') as fd:
        document = [fd.read()]

    poller = text_analytics_client.begin_extract_summary(
        document, max_sentence_count=3)
    extract_summary_results = poller.result()
    for result in extract_summary_results:
        if result.kind == "ExtractiveSummarization":
            # translate the summary to Japanese
            translation = translator_client.translate([{"text": result.sentences[0].text}], to=["zh-Hant"])
            # print translated summary
            print("...Translated to Japanese: {}".format(translation[0].translations[0].text))
        elif result.is_error is True:
            print("...Is an error with code '{}' and message '{}'".format(
                result.error.code, result.error.message
            ))
    # [END extract_summary]


if __name__ == "__main__":
    sample_extractive_summarization()
