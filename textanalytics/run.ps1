# find the key and endpoint in the Azure portal
$env:AZURE_LANGUAGE_KEY = (Get-AzCognitiveServicesAccountKey -Name "lang-deleteme" -ResourceGroupName "rg-cog").Key1
$env:AZURE_LANGUAGE_ENDPOINT = (Get-AzCognitiveServicesAccount -Name "lang-deleteme" -ResourceGroupName "rg-cog").Endpoint
$env:TRANSLATOR_KEY = (Get-AzCognitiveServicesAccountKey -Name "translate-deleteme" -ResourceGroupName "rg-cog").Key1
$env:TRANSLATOR_ENDPOINT = (Get-AzCognitiveServicesAccount -Name "translate-deleteme" -ResourceGroupName "rg-cog").Endpoint

# run the script
python sample_abstractive_summary.py
python sample_extract_summary.py