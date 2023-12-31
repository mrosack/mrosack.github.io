+++
title = "Searching Family Photos With Azure AI Search"
date = "2023-12-30T12:07:32Z"
author = "Mike Rosack"
authorTwitter = "mike_rosack" #do not include @
cover = ""
tags = ["azure", "ai", "search", "images", "photos"]
keywords = ["azure", "ai", "search", "images", "photos"]
readingTime = true
+++

My son Calvin is about 6 years old now, and ever since he's born we've had a messaging group between the whole family where we post updates and pictures, and I've been archiving that to a website that isn't public for obvious reasons.  Anyway, we've got a couple thousand images in there, and the thread is 6 years old, so finding stuff is becoming a pain.  I could search on the messages in the thread pretty easily, but I wanted some way to search images as well.  I was hoping ChatGPT or something could just do this for me but it doesn't seem like we're quite there yet.  Thankfully I've got $150/month of credits in Azure that still seem to replenish every month for some reason, and it turns out Azure's got some nifty tools to do this.

That said, it's not really obvious how to do it, and I didn't really see a straightforward guide, so I'm writing down what I did here.  It's pretty easy once you know all the secret JSON configuration to get everything working.

## Create Azure AI Services Account

For all of this, you'll need an "Azure AI services" account created.  You can mess around with this a bit in the free tiers, but if you're doing hundreds/thousands of images you'll need this plan to get billed.  And you'll definitely get billed - I got charged about 60 bucks for processing about 3500 images, so be careful what you throw at this.  All you really need to do is create the account, we'll do the rest elsewhere, this just needs to exist.

## Create Azure AI Search Service

The meat of the setup is in Azure AI Search.  You should only need to use the free tier here, 50 MB is quite a bit of space, I used about 6.5 MB for those 3500 pictures.

### Data Source

The first thing you need to do once your search service is set up is to create a data source.  I had all of my images in blob storage in Azure so I just created a datasource pointing at that storage account.


### Index

The next 3 steps all sorta bleed together, so it can be confusing what to set up first.  The index logically should be set up first because you need to define all the fields where data should be stored, but how do you know what fields to create?  Hopefully you would figure out some google query that would take you to this page: https://learn.microsoft.com/en-us/azure/search/cognitive-search-skill-image-analysis.  You should take a look at that page, as there's some stuff like Faces and Objects that I didn't include in my index, but here's the JSON I wound up using.  You can use "Add index (JSON)" and paste this in:

{{<code language="json">}}
{
    "name": "image-analysis",
    "defaultScoringProfile": null,
    "fields": [
        {
            "name": "metadata_storage_name",
            "type": "Edm.String",
            "searchable": true,
            "filterable": false,
            "facetable": false,
            "key": true,
            "sortable": true
        },
        {
            "name": "metadata_storage_path",
            "type": "Edm.String",
            "searchable": true,
            "filterable": false,
            "facetable": false,
            "sortable": true
        },
        {
            "name": "content",
            "type": "Edm.String",
            "sortable": false,
            "searchable": true,
            "filterable": false,
            "facetable": false
        },
        {
            "name": "brands",
            "type": "Collection(Edm.ComplexType)",
            "fields": [
                {
                    "name": "name",
                    "type": "Edm.String",
                    "searchable": true,
                    "filterable": false,
                    "facetable": false
                },
                {
                    "name": "confidence",
                    "type": "Edm.Double",
                    "searchable": false,
                    "filterable": false,
                    "facetable": false
                },
                {
                    "name": "rectangle",
                    "type": "Edm.ComplexType",
                    "fields": [
                        {
                            "name": "x",
                            "type": "Edm.Int32",
                            "searchable": false,
                            "filterable": false,
                            "facetable": false
                        },
                        {
                            "name": "y",
                            "type": "Edm.Int32",
                            "searchable": false,
                            "filterable": false,
                            "facetable": false
                        },
                        {
                            "name": "w",
                            "type": "Edm.Int32",
                            "searchable": false,
                            "filterable": false,
                            "facetable": false
                        },
                        {
                            "name": "h",
                            "type": "Edm.Int32",
                            "searchable": false,
                            "filterable": false,
                            "facetable": false
                        }
                    ]
                }
            ]
        },
        {
            "name": "categories",
            "type": "Collection(Edm.ComplexType)",
            "fields": [
                {
                    "name": "name",
                    "type": "Edm.String",
                    "searchable": true,
                    "filterable": false,
                    "facetable": false
                },
                {
                    "name": "score",
                    "type": "Edm.Double",
                    "searchable": false,
                    "filterable": false,
                    "facetable": false
                },
                {
                    "name": "detail",
                    "type": "Edm.ComplexType",
                    "fields": [
                        {
                            "name": "celebrities",
                            "type": "Collection(Edm.ComplexType)",
                            "fields": [
                                {
                                    "name": "name",
                                    "type": "Edm.String",
                                    "searchable": true,
                                    "filterable": false,
                                    "facetable": false
                                },
                                {
                                    "name": "faceBoundingBox",
                                    "type": "Collection(Edm.ComplexType)",
                                    "fields": [
                                        {
                                            "name": "x",
                                            "type": "Edm.Int32",
                                            "searchable": false,
                                            "filterable": false,
                                            "facetable": false
                                        },
                                        {
                                            "name": "y",
                                            "type": "Edm.Int32",
                                            "searchable": false,
                                            "filterable": false,
                                            "facetable": false
                                        }
                                    ]
                                },
                                {
                                    "name": "confidence",
                                    "type": "Edm.Double",
                                    "searchable": false,
                                    "filterable": false,
                                    "facetable": false
                                }
                            ]
                        },
                        {
                            "name": "landmarks",
                            "type": "Collection(Edm.ComplexType)",
                            "fields": [
                                {
                                    "name": "name",
                                    "type": "Edm.String",
                                    "searchable": true,
                                    "filterable": false,
                                    "facetable": false
                                },
                                {
                                    "name": "confidence",
                                    "type": "Edm.Double",
                                    "searchable": false,
                                    "filterable": false,
                                    "facetable": false
                                }
                            ]
                        }
                    ]
                }
            ]
        },
        {
            "name": "description",
            "type": "Collection(Edm.ComplexType)",
            "fields": [
                {
                    "name": "tags",
                    "type": "Collection(Edm.String)",
                    "searchable": true,
                    "filterable": false,
                    "facetable": false
                },
                {
                    "name": "captions",
                    "type": "Collection(Edm.ComplexType)",
                    "fields": [
                        {
                            "name": "text",
                            "type": "Edm.String",
                            "searchable": true,
                            "filterable": false,
                            "facetable": false
                        },
                        {
                            "name": "confidence",
                            "type": "Edm.Double",
                            "searchable": false,
                            "filterable": false,
                            "facetable": false
                        }
                    ]
                }
            ]
        },
        {
            "name": "tags",
            "type": "Collection(Edm.ComplexType)",
            "fields": [
                {
                    "name": "name",
                    "type": "Edm.String",
                    "searchable": true,
                    "filterable": false,
                    "facetable": false
                },
                {
                    "name": "hint",
                    "type": "Edm.String",
                    "searchable": true,
                    "filterable": false,
                    "facetable": false
                },
                {
                    "name": "confidence",
                    "type": "Edm.Double",
                    "searchable": false,
                    "filterable": false,
                    "facetable": false
                }
            ]
        }
    ],
    "corsOptions": {
        "allowedOrigins": [
            "*"
        ],
        "maxAgeInSeconds": 300
    }
}
{{</code>}}

Note the corsOptions at the bottom - I have a website that's going to be querying this index directly so I need CORS to be able to hit it from a browser.  You could obviously narrow the origins down if you're paranoid about it.


### Skillset

After we've got the index created, we need to create a skillset, which will tell the Azure AI what to do with our data.  We want Azure AI to look at our images and describe/tag them so we can search them, so let's set that up.  Unfortunately the default JSON they give you in the portal isn't anywhere close to what you need, but again I've got a good example here:

{{<code language="json">}}
{
    "name": "image-analysis",
    "description": "",
    "skills": [
        {
            "@odata.type": "#Microsoft.Skills.Vision.ImageAnalysisSkill",
            "name": "#1",
            "description": "",
            "context": "/document/normalized_images/*",
            "defaultLanguageCode": "en",
            "visualFeatures": [
                "Brands",
                "Categories",
                "Description",
                "Tags"
            ],
            "details": [
                "Landmarks"
            ],
            "inputs": [
                {
                    "name": "image",
                    "source": "/document/normalized_images/*"
                }
            ],
            "outputs": [
                {
                    "name": "brands"
                },
                {
                    "name": "categories"
                },
                {
                    "name": "description"
                },
                {
                    "name": "tags"
                }
            ]
        }
    ],
    "cognitiveServices": {
        "@odata.type": "#Microsoft.Azure.Search.DefaultCognitiveServices",
        "description": null
    },
    "knowledgeStore": null,
    "indexProjections": null,
    "encryptionKey": null
}
{{</code>}}

To summarize what's going on here: The skill is going to receive a normalized image from the indexer (that we'll configure in the next step) as an input, search the image for Brands, Categories, Descriptions and Tags and spit those out as outputs.


### Indexer

The indexer ties everything together - it takes data from the datasource, passes it to the skill, and writes the results to the index for searching.  My indexer config looked like this:

{{<code language="json">}}
{
    "name": "image-analysis",
    "description": null,
    "dataSourceName": "imageanalysis",
    "skillsetName": "image-analysis",
    "targetIndexName": "image-analysis",
    "disabled": null,
    "schedule": null,
    "parameters": {
        "batchSize": null,
        "maxFailedItems": null,
        "maxFailedItemsPerBatch": null,
        "base64EncodeKeys": true,
        "configuration": {
            "indexedFileNameExtensions": ".jpg,.jpeg,.gif,.png",
            "imageAction": "generateNormalizedImages"
        }
    },
    "fieldMappings": [],
    "outputFieldMappings": [
        {
            "sourceFieldName": "/document/normalized_images/*/brands/*",
            "targetFieldName": "brands"
        },
        {
            "sourceFieldName": "/document/normalized_images/*/categories/*",
            "targetFieldName": "categories"
        },
        {
            "sourceFieldName": "/document/normalized_images/*/description",
            "targetFieldName": "description"
        },
        {
            "sourceFieldName": "/document/normalized_images/*/tags/*",
            "targetFieldName": "tags"
        }
    ],
    "cache": null,
    "encryptionKey": null
}
{{</code>}}

Some critical stuff to understand in here:

* **base64EncodeKeys**: The filename of the image is used as the key in our index, and we can't have special characters in the key field.  This encodes the filename in base64 so it's guaranteed to be safe as a key.
* **indexedFileNameExtensions**: The extensions of files we want to analyze - just images.
* **imageAction**: We need to run generateNormalizedImages to create the standard images that we pass into the skill for analysis.

Once you hit save here, it'll automatically run your indexer, so make sure you're ready to be billed!

## Results

Hopefully everything went well, it'll probably take a while to churn through all of the images if you've got a bit.  But when it's done you'll have data about your images ready to be searched in your index!  Just go to your index in the portal and type something in the search field and see what comes up.  The search field is pretty smart and covers all the fields in your documents, so you should have pretty good results right off the bat.  If you need to customize your search and integrate it into a webapp or something, this doc was really helpful: https://learn.microsoft.com/en-us/rest/api/searchservice/search-documents

A couple highlights:

* **searchMode**: The options here are "any" or "all" - by default it's any, which works like ORing your search terms.  if you want AND, use "all".
* **$top**: If you don't want to page and just want a ton of results, you can set this up to 1000.

## Next Steps

I didn't do any face detection here, because all it does is locate faces in images and not identify them (unless they're "Celebrities").  I'd like to be able to train something to identify family members in pictures and include them as searchable keys.  Microsoft does have a Face API service that can do this, but how to get the face detections in the search results?  Fortunately, AI Search seems to support "custom skills" (see https://github.com/Azure-Samples/azure-search-power-skills), so I think I can write a bridge skill that will search for known faces in Face API and return those as keys to be included in the index.  Maybe I'll have another post this year with that...