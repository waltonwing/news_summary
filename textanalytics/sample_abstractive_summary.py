# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------

"""
FILE: sample_abstractive_summary.py

DESCRIPTION:
    This sample demonstrates how to submit text documents for abstractive text summarization.
    Abstractive summarization is available as an action type through the begin_analyze_actions API.

    Abstractive summarization generates a summary that may not use the same words as those in
    the document, but captures the main idea.

    The abstractive summarization feature is part of a gated preview. Request access here:
    https://aka.ms/applyforgatedsummarizationfeatures

USAGE:
    python sample_abstractive_summary.py

    Set the environment variables with your own values before running the sample:
    1) AZURE_LANGUAGE_ENDPOINT - the endpoint to your Language resource.
    2) AZURE_LANGUAGE_KEY - your Language subscription key
"""


def sample_abstractive_summarization() -> None:
    # [START abstractive_summary]
    import os
    from azure.core.credentials import AzureKeyCredential
    from azure.ai.textanalytics import TextAnalyticsClient

    endpoint = os.environ["AZURE_LANGUAGE_ENDPOINT"]
    key = os.environ["AZURE_LANGUAGE_KEY"]

    text_analytics_client = TextAnalyticsClient(
        endpoint=endpoint,
        credential=AzureKeyCredential(key),
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

    poller = text_analytics_client.begin_abstractive_summary(document)
    abstractive_summary_results = poller.result()
    for result in abstractive_summary_results:
        if result.kind == "AbstractiveSummarization":
            print("Summaries abstracted:")
            [print(f"{summary.text}\n") for summary in result.summaries]
        elif result.is_error is True:
            print("...Is an error with code '{}' and message '{}'".format(
                result.error.code, result.error.message
            ))
    # [END abstractive_summary]


if __name__ == "__main__":
    sample_abstractive_summarization()
