defmodule Integration.TopicTest do
  use ExUnit.Case, async: true
  setup {Integration, :setup_client}
  setup {Integration, :setup_namespace}

  # Topic APIs
  test "topics CRUD", ctx do
    namespace = ctx.namespace

    topic_ref_1 = "integration-test-topic-#{ctx.machine.id}-1"
    topic_ref_2 = "integration-test-topic-#{ctx.machine.id}-2"

    {:ok, topic_1} =
      MoriaClient.create_topic(ctx.client, %{
        reference: topic_ref_1,
        namespace_id: namespace.id
      })

    assert topic_1.reference == topic_ref_1

    {:ok, _topic_2} =
      MoriaClient.create_topic(ctx.client, %{
        reference: topic_ref_2,
        namespace_id: namespace.id
      })

    # can paginate topics
    assert {:ok, page_1} =
             MoriaClient.list_topics(ctx.client,
               first: 1,
               after: nil,
               filters: [%{field: :namespace_id, value: namespace.id}]
             )

    assert page_1.page.has_next_page
    assert %{topics: [%{reference: ^topic_ref_1}]} = page_1

    # next page
    assert {:ok, page_2} =
             MoriaClient.list_topics(ctx.client,
               first: 1,
               after: page_1.page.end_cursor,
               filters: [%{field: :namespace_id, value: namespace.id}]
             )

    refute page_2.page.has_next_page
    assert %{topics: [%{reference: ^topic_ref_2}]} = page_2

    # Can stream topics via stream_topics/2
    # (we set first: 1 to force multiple pages)
    assert [
             %{reference: ^topic_ref_1},
             %{reference: ^topic_ref_2}
           ] =
             MoriaClient.stream_topics!(ctx.client,
               first: 1,
               filters: [%{field: :namespace_id, value: namespace.id}]
             )
             |> Enum.to_list()

    # can update topic
    {:ok, updated_topic} =
      MoriaClient.update_topic(ctx.client, topic_1.id, %{description: "updated"})

    assert updated_topic.description == "updated"

    # can get topic by id
    {:ok, topic_by_id} = MoriaClient.get_topic(ctx.client, topic_1.id)
    assert topic_by_id.id == topic_1.id
    assert topic_by_id.reference == topic_ref_1

    # can delete topic
    :ok = MoriaClient.delete_topic(ctx.client, topic_1.id)

    # deleted topic is no longer found
    {:error, _reason} = MoriaClient.get_topic(ctx.client, topic_1.id)
  end

  test "topic device summary", ctx do
    namespace = ctx.namespace

    topic_ref = "integration-test-topic-#{ctx.machine.id}-1"

    {:ok, topic} =
      MoriaClient.create_topic(ctx.client, %{
        reference: topic_ref,
        namespace_id: namespace.id
      })

    json = %{
      "device" => %{
        "identity" => %{
          "dlms_flag_id" => "KAM",
          "identification_number" => "12345678"
        }
      }
    }

    assert {:ok, _page} =
             MoriaClient.create_messages(ctx.client, [
               %{
                 topic_id: topic.id,
                 payload: JSON.encode!(json),
                 payload_type: "application/json"
               },
               %{
                 topic_id: topic.id,
                 payload: "2",
                 payload_type: "text/plain"
               },
               %{
                 topic_id: topic.id,
                 payload_type: "wmbus",
                 # KAM 12345678:
                 payload:
                   "35442D2C7856341233028D20BA80424A2095EFA9766042ECCA96DDE335C9DCF0589FF3F83575C94D09009FD99F582EACFB0E43E577D4",
                 payload_encoding: "hex"
               }
             ])

    # Wait a bit, because processing devices is async.
    # I know, but we have no wait to wait on the server for this.
    Process.sleep(500)
    assert {:ok, device_summary} = MoriaClient.get_topic_device_summary(ctx.client, topic.id)

    assert [
             %{
               identification: %{
                 dlms_flag_id: "KAM",
                 identification_number: "12345678"
               }
             }
           ] = device_summary.devices
  end
end
