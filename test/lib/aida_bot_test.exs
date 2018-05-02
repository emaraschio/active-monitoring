defmodule ActiveMonitoring.AidaBotTest do
  use ActiveMonitoring.ModelCase
  use Timex
  import ActiveMonitoring.Factory
  import Mock

  alias ActiveMonitoring.{AidaBot, Campaign}

  setup do
    [campaign: insert(:campaign)]
  end

  describe "manifest" do
    test "it should be a version 1 manifest", context do
      manifest =
        context[:campaign]
        |> AidaBot.manifest()

      assert manifest[:version] == "1"
    end

    test "it takes languages from campaign", context do
      manifest =
        context[:campaign]
        |> AidaBot.manifest()

      assert manifest[:languages] == ["en", "es"]
    end

    test "there is a greeting for each language", context do
      manifest =
        context[:campaign]
        |> AidaBot.manifest()

      assert manifest[:front_desk][:greeting][:message] == %{
               "en" => "Hello!",
               "es" => "Hello!"
             }
    end

    test "there is a not_understood message for each language", context do
      manifest =
        context[:campaign]
        |> AidaBot.manifest()

      assert manifest[:front_desk][:not_understood][:message] == %{
               "en" => "Sorry, I did not understood that",
               "es" => "Sorry, I did not understood that"
             }
    end

    test "there is a clarification message for each language", context do
      manifest =
        context[:campaign]
        |> Campaign.with_chat_text(%{
          topic: "registration",
          language: "en",
          value: "Send \"registration\" to register for the campaign"
        })
        |> Campaign.with_chat_text(%{
          topic: "registration",
          language: "es",
          value: "Envíe \"registration\" para registrarse a la campaña"
        })
        |> AidaBot.manifest()

      assert manifest[:front_desk][:clarification][:message] == %{
               "en" => "Send \"registration\" to register for the campaign",
               "es" => "Envíe \"registration\" para registrarse a la campaña"
             }
    end

    test "there is an introduction message for each language", context do
      manifest =
        context[:campaign]
        |> Campaign.with_welcome(%{
          mode: "chat",
          language: "en",
          value: "Welcome to the campaign!"
        })
        |> Campaign.with_welcome(%{
          mode: "chat",
          language: "es",
          value: "Bienvenidos a la campaña!"
        })
        |> AidaBot.manifest()

      assert manifest[:front_desk][:introduction][:message] == %{
               "en" => "Welcome to the campaign!",
               "es" => "Bienvenidos a la campaña!"
             }
    end

    test "there is a language detector skill" do
      manifest =
        insert(:campaign, %{langs: ["en", "es"]})
        |> Campaign.with_chat_text(%{
          topic: "language",
          value: "To chat in english say 'en'. Para hablar en español escribe 'es'"
        })
        |> AidaBot.manifest()

      {:ok, skill} = manifest[:skills] |> Enum.fetch(0)

      assert skill == %{
               type: "language_detector",
               explanation: "To chat in english say 'en'. Para hablar en español escribe 'es'",
               languages: %{
                 "en" => ["en"],
                 "es" => ["es"]
               }
             }
    end

    test "there is no language detector skill if the campaign has only one language" do
      manifest =
        insert(:campaign, %{langs: ["en"]})
        |> Campaign.with_chat_text(%{
          topic: "language",
          value: "To chat in english say 'en'. Para hablar en español escribe 'es'"
        })
        |> AidaBot.manifest()

      assert manifest[:skills] |> Enum.count() == 1

      {:ok, survey} = manifest[:skills] |> Enum.fetch(0)

      assert survey[:id] == "registration"
    end

    test "it should have a survey with a text question to ask for the registration identifier" do
      campaign =
        insert(:campaign, %{langs: ["en", "es"]})
        |> Campaign.with_chat_text(%{
          topic: "identify",
          language: "en",
          value: "Please tell me your Registration Id"
        })
        |> Campaign.with_chat_text(%{
          topic: "identify",
          language: "es",
          value: "Por favor dígame su número de registro"
        })
        |> Campaign.with_chat_text(%{
          topic: "thanks",
          language: "en",
          value: "thanks!"
        })
        |> Campaign.with_chat_text(%{
          topic: "thanks",
          language: "es",
          value: "gracias!"
        })

      manifest =
        campaign
        |> AidaBot.manifest()

      {:ok, skill} = manifest[:skills] |> Enum.fetch(1)

      assert skill == %{
               type: "survey",
               id: "registration",
               name: "registration",
               keywords: %{
                 "en" => ["registration"],
                 "es" => ["registration"]
               },
               questions: [
                 %{
                   type: "text",
                   name: "registration_id",
                   message: %{
                     "en" => "Please tell me your Registration Id",
                     "es" => "Por favor dígame su número de registro"
                   }
                 },
                 %{
                   type: "note",
                   name: "thanks",
                   message: %{
                     "en" => "thanks!",
                     "es" => "gracias!"
                   }
                 }
               ],
               choice_lists: []
             }
    end

    test "it shouldn't have a survey without subjects" do
      campaign =
        insert(:campaign, %{langs: ["en", "es"]})
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440111",
          language: "en",
          value: "Do you have fever?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440111",
          language: "es",
          value: "¿Tiene usted fiebre?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440222",
          language: "en",
          value: "Do you have rash?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440222",
          language: "es",
          value: "¿Tiene alguna erupción?"
        })

      manifest =
        campaign
        |> AidaBot.manifest()

      assert manifest[:skills] |> Enum.count() == 2
    end

    test "surveys should have a question for every symptom" do
      campaign =
        insert(:campaign, %{langs: ["en", "es"], additional_information: nil})
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440111",
          language: "en",
          value: "Do you have fever?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440111",
          language: "es",
          value: "¿Tiene usted fiebre?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440222",
          language: "en",
          value: "Do you have rash?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440222",
          language: "es",
          value: "¿Tiene alguna erupción?"
        })
        |> Campaign.with_chat_text(%{
          topic: "thanks",
          language: "en",
          value: "thanks!"
        })
        |> Campaign.with_chat_text(%{
          topic: "thanks",
          language: "es",
          value: "Gracias!"
        })

      subject1 = insert(:subject, campaign: campaign)
      subject2 = insert(:subject, campaign: campaign)

      relevance =
        "${survey\/registration\/registration_id} = \"#{subject1.registration_identifier}\" " <>
          "or ${survey\/registration\/registration_id} = \"#{subject2.registration_identifier}\""

      manifest =
        campaign
        |> AidaBot.manifest(%{1 => [subject1, subject2]})

      survey_start = {Timex.today() |> Timex.to_erl(), {15, 0, 0}}

      schedule =
        Timex.Timezone.resolve(campaign.timezone, survey_start)
        |> DateTime.to_iso8601()

      {:ok, skill} = manifest[:skills] |> Enum.fetch(2)

      assert skill ==
               %{
                 type: "survey",
                 id: "1",
                 name: "survey_1",
                 schedule: schedule,
                 relevant: relevance,
                 questions: [
                   %{
                     type: "select_one",
                     choices: "yes_no",
                     name: "symptom:123e4567-e89b-12d3-a456-426655440111",
                     message: %{
                       "en" => "Do you have fever?",
                       "es" => "¿Tiene usted fiebre?"
                     }
                   },
                   %{
                     type: "select_one",
                     choices: "yes_no",
                     name: "symptom:123e4567-e89b-12d3-a456-426655440222",
                     message: %{
                       "en" => "Do you have rash?",
                       "es" => "¿Tiene alguna erupción?"
                     }
                   },
                   %{
                     type: "note",
                     name: "thanks",
                     message: %{
                       "en" => "thanks!",
                       "es" => "Gracias!"
                     }
                   }
                 ],
                 choice_lists: [
                   %{
                     name: "yes_no",
                     choices: [
                       %{
                         name: "yes",
                         labels: %{
                           "en" => ["yes"],
                           "es" => ["yes"]
                         }
                       },
                       %{
                         name: "no",
                         labels: %{
                           "en" => ["no"],
                           "es" => ["no"]
                         }
                       }
                     ]
                   }
                 ]
               }
    end

    test "should have one survey per monitor duration day if there is at least one subject for that day" do
      campaign =
        insert(:campaign, %{langs: ["en", "es"], monitor_duration: 3, additional_information: nil})
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440111",
          language: "en",
          value: "Do you have fever?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440111",
          language: "es",
          value: "¿Tiene usted fiebre?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440222",
          language: "en",
          value: "Do you have rash?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440222",
          language: "es",
          value: "¿Tiene alguna erupción?"
        })
        |> Campaign.with_chat_text(%{
          topic: "thanks",
          language: "en",
          value: "thanks!"
        })
        |> Campaign.with_chat_text(%{
          topic: "thanks",
          language: "es",
          value: "¡Gracias!"
        })

      subject1 = insert(:subject, campaign: campaign)
      subject2 = insert(:subject, campaign: campaign)

      subject3 = insert(:subject, campaign: campaign)

      relevance1 =
        "${survey\/registration\/registration_id} = \"#{subject1.registration_identifier}\" " <>
          "or ${survey\/registration\/registration_id} = \"#{subject2.registration_identifier}\""

      relevance3 = "${survey\/registration\/registration_id} = \"#{subject3.registration_identifier}\""

      manifest =
        campaign
        |> AidaBot.manifest(%{1 => [subject1, subject2], 3 => [subject3]})

      assert manifest[:skills] |> Enum.count() == 4

      survey_start = {Timex.today() |> Timex.to_erl(), {15, 0, 0}}

      schedule =
        Timex.Timezone.resolve(campaign.timezone, survey_start)
        |> DateTime.to_iso8601()

      {:ok, skill} = manifest[:skills] |> Enum.fetch(2)

      assert skill ==
               %{
                 type: "survey",
                 id: "1",
                 name: "survey_1",
                 schedule: schedule,
                 relevant: relevance1,
                 questions: [
                   %{
                     type: "select_one",
                     choices: "yes_no",
                     name: "symptom:123e4567-e89b-12d3-a456-426655440111",
                     message: %{
                       "en" => "Do you have fever?",
                       "es" => "¿Tiene usted fiebre?"
                     }
                   },
                   %{
                     type: "select_one",
                     choices: "yes_no",
                     name: "symptom:123e4567-e89b-12d3-a456-426655440222",
                     message: %{
                       "en" => "Do you have rash?",
                       "es" => "¿Tiene alguna erupción?"
                     }
                   },
                   %{
                     type: "note",
                     name: "thanks",
                     message: %{
                       "en" => "thanks!",
                       "es" => "¡Gracias!"
                     }
                   }
                 ],
                 choice_lists: [
                   %{
                     name: "yes_no",
                     choices: [
                       %{
                         name: "yes",
                         labels: %{
                           "en" => ["yes"],
                           "es" => ["yes"]
                         }
                       },
                       %{
                         name: "no",
                         labels: %{
                           "en" => ["no"],
                           "es" => ["no"]
                         }
                       }
                     ]
                   }
                 ]
               }

      {:ok, skill} = manifest[:skills] |> Enum.fetch(3)

      assert skill ==
               %{
                 type: "survey",
                 id: "3",
                 name: "survey_3",
                 schedule: schedule,
                 relevant: relevance3,
                 questions: [
                   %{
                     type: "select_one",
                     choices: "yes_no",
                     name: "symptom:123e4567-e89b-12d3-a456-426655440111",
                     message: %{
                       "en" => "Do you have fever?",
                       "es" => "¿Tiene usted fiebre?"
                     }
                   },
                   %{
                     type: "select_one",
                     choices: "yes_no",
                     name: "symptom:123e4567-e89b-12d3-a456-426655440222",
                     message: %{
                       "en" => "Do you have rash?",
                       "es" => "¿Tiene alguna erupción?"
                     }
                   },
                   %{
                     type: "note",
                     name: "thanks",
                     message: %{
                       "en" => "thanks!",
                       "es" => "¡Gracias!"
                     }
                   }
                 ],
                 choice_lists: [
                   %{
                     name: "yes_no",
                     choices: [
                       %{
                         name: "yes",
                         labels: %{
                           "en" => ["yes"],
                           "es" => ["yes"]
                         }
                       },
                       %{
                         name: "no",
                         labels: %{
                           "en" => ["no"],
                           "es" => ["no"]
                         }
                       }
                     ]
                   }
                 ]
               }
    end

    test "surveys should include optional educational information" do
      campaign =
        insert(:campaign, %{langs: ["en"], additional_information: "optional"})
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440111",
          language: "en",
          value: "Do you have fever?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440222",
          language: "en",
          value: "Do you have rash?"
        })
        |> Campaign.with_chat_text(%{
          topic: "additional_information_intro",
          language: "en",
          value: "additional_information_intro copy"
        })
        |> Campaign.with_chat_text(%{
          topic: "educational",
          language: "en",
          value: "educational copy"
        })
        |> Campaign.with_chat_text(%{
          topic: "thanks",
          language: "en",
          value: "thanks!"
        })

      subject1 = insert(:subject, campaign: campaign)
      subject2 = insert(:subject, campaign: campaign)

      relevance =
        "${survey\/registration\/registration_id} = \"#{subject1.registration_identifier}\" " <>
          "or ${survey\/registration\/registration_id} = \"#{subject2.registration_identifier}\""

      manifest =
        campaign
        |> AidaBot.manifest(%{1 => [subject1, subject2]})

      survey_start = {Timex.today() |> Timex.to_erl(), {15, 0, 0}}

      schedule =
        Timex.Timezone.resolve(campaign.timezone, survey_start)
        |> DateTime.to_iso8601()

      {:ok, skill} = manifest[:skills] |> Enum.fetch(1)

      assert skill == %{
               type: "survey",
               id: "1",
               name: "survey_1",
               schedule: schedule,
               relevant: relevance,
               questions: [
                 %{
                   type: "select_one",
                   choices: "yes_no",
                   name: "symptom:123e4567-e89b-12d3-a456-426655440111",
                   message: %{
                     "en" => "Do you have fever?"
                   }
                 },
                 %{
                   type: "select_one",
                   choices: "yes_no",
                   name: "symptom:123e4567-e89b-12d3-a456-426655440222",
                   message: %{
                     "en" => "Do you have rash?"
                   }
                 },
                 %{
                   type: "select_one",
                   choices: "yes_no",
                   name: "additional_information",
                   message: %{
                     "en" => "additional_information_intro copy"
                   }
                 },
                 %{
                   type: "note",
                   name: "educational",
                   relevant: "${survey\/1\/additional_information} = 'yes'",
                   message: %{
                     "en" => "educational copy"
                   }
                 },
                 %{
                   type: "note",
                   name: "thanks",
                   message: %{
                     "en" => "thanks!"
                   }
                 }
               ],
               choice_lists: [
                 %{
                   name: "yes_no",
                   choices: [
                     %{
                       name: "yes",
                       labels: %{
                         "en" => ["yes"]
                       }
                     },
                     %{
                       name: "no",
                       labels: %{
                         "en" => ["no"]
                       }
                     }
                   ]
                 }
               ]
             }
    end

    test "surveys should include compulsory educational information" do
      campaign =
        insert(:campaign, %{langs: ["en"], additional_information: "compulsory"})
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440111",
          language: "en",
          value: "Do you have fever?"
        })
        |> Campaign.with_chat_text(%{
          topic: "symptom:123e4567-e89b-12d3-a456-426655440222",
          language: "en",
          value: "Do you have rash?"
        })
        |> Campaign.with_chat_text(%{
          topic: "additional_information_intro",
          language: "en",
          value: "additional_information_intro copy"
        })
        |> Campaign.with_chat_text(%{
          topic: "educational",
          language: "en",
          value: "educational copy"
        })
        |> Campaign.with_chat_text(%{
          topic: "thanks",
          language: "en",
          value: "thanks!"
        })

      subject1 = insert(:subject, campaign: campaign)
      subject2 = insert(:subject, campaign: campaign)

      relevance =
        "${survey\/registration\/registration_id} = \"#{subject1.registration_identifier}\" " <>
          "or ${survey\/registration\/registration_id} = \"#{subject2.registration_identifier}\""

      manifest =
        campaign
        |> AidaBot.manifest(%{1 => [subject1, subject2]})

      survey_start = {Timex.today() |> Timex.to_erl(), {15, 0, 0}}

      schedule =
        Timex.Timezone.resolve(campaign.timezone, survey_start)
        |> DateTime.to_iso8601()

      {:ok, skill} = manifest[:skills] |> Enum.fetch(1)

      assert skill ==
               %{
                 type: "survey",
                 id: "1",
                 name: "survey_1",
                 schedule: schedule,
                 relevant: relevance,
                 questions: [
                   %{
                     type: "select_one",
                     choices: "yes_no",
                     name: "symptom:123e4567-e89b-12d3-a456-426655440111",
                     message: %{
                       "en" => "Do you have fever?"
                     }
                   },
                   %{
                     type: "select_one",
                     choices: "yes_no",
                     name: "symptom:123e4567-e89b-12d3-a456-426655440222",
                     message: %{
                       "en" => "Do you have rash?"
                     }
                   },
                   %{
                     type: "note",
                     name: "educational",
                     message: %{
                       "en" => "educational copy"
                     }
                   },
                   %{
                     type: "note",
                     name: "thanks",
                     message: %{
                       "en" => "thanks!"
                     }
                   }
                 ],
                 choice_lists: [
                   %{
                     name: "yes_no",
                     choices: [
                       %{
                         name: "yes",
                         labels: %{
                           "en" => ["yes"]
                         }
                       },
                       %{
                         name: "no",
                         labels: %{
                           "en" => ["no"]
                         }
                       }
                     ]
                   }
                 ]
               }
    end

    test "should have a websocket channel and a facebook channel" do
      manifest =
        insert(:campaign, %{
          langs: ["en"],
          fb_page_id: "the_page_id",
          fb_verify_token: "the_verify_token",
          fb_access_token: "the_access_token"
        })
        |> Campaign.with_chat_text(%{
          topic: "language",
          value: "To chat in english say 'en'. Para hablar en español escribe 'es'"
        })
        |> AidaBot.manifest()

      assert manifest[:channels] == [
               %{
                 type: "facebook",
                 page_id: "the_page_id",
                 verify_token: "the_verify_token",
                 access_token: "the_access_token"
               },
               %{
                 type: "websocket",
                 access_token: "the_access_token"
               }
             ]
    end
  end

  describe "publish" do
    test "should send the manifest to aida" do
      with_mock HTTPoison,
        post: fn _url, _body, _params ->
          {
            :ok,
            %HTTPoison.Response{
              body:
                %{
                  data: %{
                    id: "82f0c3dd-7313-4896-9797-f0479e236219",
                    manifest: "Stored Manifest",
                    temp: false
                  }
                }
                |> Poison.encode!()
            }
          }
        end do
        response =
          "THE MANIFEST"
          |> AidaBot.publish()

        assert response == %{
                 "id" => "82f0c3dd-7313-4896-9797-f0479e236219",
                 "manifest" => "Stored Manifest",
                 "temp" => false
               }

        assert called(
                 HTTPoison.post(
                   "http://aida-backend/api/bots",
                   %{bot: %{manifest: "THE MANIFEST"}} |> Poison.encode!(),
                   [{'Accept', 'application/json'}, {"Content-Type", "application/json"}]
                 )
               )
      end
    end

    test "should update the manifest" do
      with_mock HTTPoison,
        put: fn _url, _body, _params ->
          {
            :ok,
            %HTTPoison.Response{
              body:
                %{
                  data: %{
                    id: "e8762231-d624-4986-ac2d-b8a4d95f7226",
                    manifest: "Stored Manifest",
                    temp: false
                  }
                }
                |> Poison.encode!()
            }
          }
        end do
        response =
          "THE MANIFEST"
          |> AidaBot.update("e8762231-d624-4986-ac2d-b8a4d95f7226")

        assert response == %{
                 "id" => "e8762231-d624-4986-ac2d-b8a4d95f7226",
                 "manifest" => "Stored Manifest",
                 "temp" => false
               }

        assert called(
                 HTTPoison.put(
                   "http://aida-backend/api/bots/e8762231-d624-4986-ac2d-b8a4d95f7226",
                   %{bot: %{manifest: "THE MANIFEST"}} |> Poison.encode!(),
                   [{'Accept', 'application/json'}, {"Content-Type", "application/json"}]
                 )
               )
      end
    end
  end
end
