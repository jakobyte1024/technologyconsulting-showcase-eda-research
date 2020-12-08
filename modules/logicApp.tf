resource "azurerm_logic_app_workflow" "logic_app_event_producer" {
    name = "tc-eda-iac-${var.environment}-customer-changed-event-producer"
    location = azurerm_resource_group.resourceGroup.location
    resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_logic_app_trigger_recurrence" "logic_app_event_producer_trigger" {
    name = "To be triggered manually"
    logic_app_id = azurerm_logic_app_workflow.logic_app_event_producer.id
    # We just want to trigger it manually, so we'll set the frequency as low as possible
    frequency = "Month"
    interval = 2
}

resource "azurerm_logic_app_action_custom" "logic_app_event_producer_action_1" {
    name = "Initialize_variable"
    logic_app_id = azurerm_logic_app_workflow.logic_app_event_producer.id
    body = <<BODY
    {
                "inputs": {
                    "variables": [
                        {
                            "name": "i",
                            "type": "integer",
                            "value": 1
                        }
                    ]
                },
                "runAfter": {},
                "type": "InitializeVariable"
            }
    BODY
}

resource "azurerm_logic_app_action_custom" "logic_app_event_producer_action_5" {
    name = "Until"
    //Depends_on needed because terraform will throw the following error, basically deleting the logic app in the wrong order
    //Error: Error removing Action "Initialize_variable" from Logic App "tc-eda-iac-dev-customer-changed-event-producer" (Resource Group "tc-eda-iac-dev"): Error removing Action "Initialize_variable" from Logic App Workspace "tc-eda-iac-dev-customer-changed-event-producer" (Resource Group "tc-eda-iac-dev"): logic.WorkflowsClient#CreateOrUpdate: Failure responding to request: StatusCode=400 -- Original Error: autorest/azure: Service returned an error. Status=400 Code="InvalidTemplate" Message="The template validation failed: 'The 'runAfter' property of template action 'Until' at line '1' and column '180' contains non-existent action: 'Initialize_variable'.'."
    depends_on = [azurerm_logic_app_action_custom.logic_app_event_producer_action_1]
    logic_app_id = azurerm_logic_app_workflow.logic_app_event_producer.id
    body = <<BODY
    {
   "actions":{
      "For_each":{
         "actions":{
            "CallCustomerChangedFunction":{
               "inputs":{
                  "body":{
                     "address":{
                        "city":"@{items('For_each')?['location']?['city']}",
                        "street":"@{items('For_each')?['location']?['street']?['name']} @{items('For_each')?['location']?['street']?['number']}",
                        "zip":"@{items('For_each')?['location']?['postcode']}"
                     },
                     "id":"@variables('i')",
                     "name":"@{items('For_each')?['name']?['first']} @{items('For_each')?['name']?['last']}"
                  },
                  "method":"PUT",
                  "uri":"https://${azurerm_function_app.customer_function_producer.default_hostname}/api/CustomerChanged"
               },
               "runAfter":{
                  
               },
               "type":"Http"
            }
         },
         "foreach":"@body('Parse_JSON')?['results']",
         "runAfter":{
            "Parse_JSON":[
               "Succeeded"
            ]
         },
         "type":"Foreach"
      },
      "GetRandomPerson":{
         "inputs":{
            "method":"GET",
            "uri":"https://randomuser.me/api/"
         },
         "runAfter":{
            
         },
         "type":"Http"
      },
      "Increment_Variable":{
         "inputs":{
            "name":"i",
            "value":1
         },
         "runAfter":{
            "For_each":[
               "Succeeded"
            ]
         },
         "type":"IncrementVariable"
      },
      "Parse_JSON":{
         "inputs":{
            "content":"@body('GetRandomPerson')",
            "schema":{
               "properties":{
                  "info":{
                     "properties":{
                        "page":{
                           "type":"integer"
                        },
                        "results":{
                           "type":"integer"
                        },
                        "seed":{
                           "type":"string"
                        },
                        "version":{
                           "type":"string"
                        }
                     },
                     "type":"object"
                  },
                  "results":{
                     "items":{
                        "properties":{
                           "cell":{
                              "type":"string"
                           },
                           "dob":{
                              "properties":{
                                 "age":{
                                    "type":"integer"
                                 },
                                 "date":{
                                    "type":"string"
                                 }
                              },
                              "type":"object"
                           },
                           "email":{
                              "type":"string"
                           },
                           "gender":{
                              "type":"string"
                           },
                           "id":{
                              "properties":{
                                 "name":{
                                    "type":"string"
                                 },
                                 "value":{
                                    
                                 }
                              },
                              "type":"object"
                           },
                           "location":{
                              "properties":{
                                 "city":{
                                    "type":"string"
                                 },
                                 "coordinates":{
                                    "properties":{
                                       "latitude":{
                                          "type":"string"
                                       },
                                       "longitude":{
                                          "type":"string"
                                       }
                                    },
                                    "type":"object"
                                 },
                                 "country":{
                                    "type":"string"
                                 },
                                 "postcode":{
                                    "type":[
                                       "string",
                                       "integer"
                                    ]
                                 },
                                 "state":{
                                    "type":"string"
                                 },
                                 "street":{
                                    "properties":{
                                       "name":{
                                          "type":"string"
                                       },
                                       "number":{
                                          "type":"integer"
                                       }
                                    },
                                    "type":"object"
                                 },
                                 "timezone":{
                                    "properties":{
                                       "description":{
                                          "type":"string"
                                       },
                                       "offset":{
                                          "type":"string"
                                       }
                                    },
                                    "type":"object"
                                 }
                              },
                              "type":"object"
                           },
                           "login":{
                              "properties":{
                                 "md5":{
                                    "type":"string"
                                 },
                                 "password":{
                                    "type":"string"
                                 },
                                 "salt":{
                                    "type":"string"
                                 },
                                 "sha1":{
                                    "type":"string"
                                 },
                                 "sha256":{
                                    "type":"string"
                                 },
                                 "username":{
                                    "type":"string"
                                 },
                                 "uuid":{
                                    "type":"string"
                                 }
                              },
                              "type":"object"
                           },
                           "name":{
                              "properties":{
                                 "first":{
                                    "type":"string"
                                 },
                                 "last":{
                                    "type":"string"
                                 },
                                 "title":{
                                    "type":"string"
                                 }
                              },
                              "type":"object"
                           },
                           "nat":{
                              "type":"string"
                           },
                           "phone":{
                              "type":"string"
                           },
                           "picture":{
                              "properties":{
                                 "large":{
                                    "type":"string"
                                 },
                                 "medium":{
                                    "type":"string"
                                 },
                                 "thumbnail":{
                                    "type":"string"
                                 }
                              },
                              "type":"object"
                           },
                           "registered":{
                              "properties":{
                                 "age":{
                                    "type":"integer"
                                 },
                                 "date":{
                                    "type":"string"
                                 }
                              },
                              "type":"object"
                           }
                        },
                        "required":[
                           "gender",
                           "name",
                           "location",
                           "email",
                           "login",
                           "dob",
                           "registered",
                           "phone",
                           "cell",
                           "id",
                           "picture",
                           "nat"
                        ],
                        "type":"object"
                     },
                     "type":"array"
                  }
               },
               "type":"object"
            }
         },
         "runAfter":{
            "GetRandomPerson":[
               "Succeeded"
            ]
         },
         "type":"ParseJson"
      }
   },
   "expression":"@equals(variables('i'), 11)",
   "limit":{
      "count":10,
      "timeout":"PT1H"
   },
   "runAfter":{
      "Initialize_variable":[
         "Succeeded"
      ]
   },
   "type":"Until"
}
    BODY
}