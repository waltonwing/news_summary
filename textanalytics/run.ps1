# find the key and endpoint in the Azure portal
$language_account_name = "cog-language"
$translator_account_name = "cog-translator-614"
$resource_group = "rg_news_summary"

$language_key = (Get-AzCognitiveServicesAccountKey -Name $language_account_name -ResourceGroupName $resource_group).Key1
$language_endpoint = (Get-AzCognitiveServicesAccount -Name $language_account_name -ResourceGroupName $resource_group).Endpoint
$translator_key = (Get-AzCognitiveServicesAccountKey -Name $translator_account_name -ResourceGroupName $resource_group).Key1
$translator_location = (Get-AzCognitiveServicesAccount -Name $translator_account_name -ResourceGroupName $resource_group).Location

# read news.txt as variable
$context = Get-Content -Path .\textanalytics\news.txt -Raw

# run the script
python .\textanalytics\extractor.py $context $language_endpoint $language_key $translator_location $translator_key
