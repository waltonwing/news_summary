# News Summary Generator

## Goal

- [ ] Automatically fetch a news article online
- [x] Use Azure Text Analytics to summarize the article
- [x] Use Azure Translator to translate the summary
- [X] Send the translated message to a phone

## Files
- sms.ps1: Main script to send result message to a phone using twilio api
- extractor.ps1: Import azure resources and call extractor.py
- extractor.py: Interact with Azure cognitive services to summarize and translate the article
- news.txt: A sample news article
- result.txt: Temp file to store the translated result
