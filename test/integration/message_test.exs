defmodule Integration.MessageTest do
  use ExUnit.Case, async: true
  setup {Integration, :setup_client}
  setup {Integration, :setup_namespace}

  # Message APIs
  test "message CRUD", ctx do
    namespace = ctx.namespace

    {:ok, topic_a} =
      MoriaClient.create_topic(ctx.client, %{
        reference: "integration-test-message-topic-a-#{ctx.machine.id}",
        namespace_id: namespace.id
      })

    {:ok, topic_b} =
      MoriaClient.create_topic(ctx.client, %{
        reference: "integration-test-message-topic-b-#{ctx.machine.id}",
        namespace_id: namespace.id
      })

    assert {:ok, page} =
             MoriaClient.create_messages(ctx.client, [
               %{topic_id: topic_a.id, payload: "1", payload_type: "text/plain"},
               %{topic_id: topic_a.id, payload: "2", payload_type: "text/plain"},
               %{topic_id: topic_a.id, payload: "3", payload_type: "text/plain"},
               %{topic_id: topic_b.id, payload: "foo", payload_type: "text/plain"},
               %{topic_id: topic_a.id, payload: "4", payload_type: "text/plain"}
             ])

    assert length(page.messages) == 5

    topic_a_id = topic_a.id
    topic_b_id = topic_b.id

    # assert order returned is order given
    assert [
             %{id: id1, topic_id: ^topic_a_id},
             %{id: id2, topic_id: ^topic_a_id},
             %{id: id3, topic_id: ^topic_a_id},
             %{id: _id4, topic_id: ^topic_b_id},
             %{id: id5, topic_id: ^topic_a_id}
           ] = page.messages

    # create by topic reference as well
    assert {:ok, page_by_ref} =
             MoriaClient.create_messages(ctx.client, [
               %{topic_reference: topic_a.reference, payload: "5", payload_type: "text/plain"},
               %{topic_reference: topic_b.reference, payload: "bar", payload_type: "text/plain"}
             ])

    assert length(page_by_ref.messages) == 2

    # grab message ids
    assert [
             %{id: id6, topic_id: ^topic_a_id},
             %{id: _id7, topic_id: ^topic_b_id}
           ] = page_by_ref.messages

    # mix topic_id and topic_reference in the same request
    assert {:ok, page_mixed} =
             MoriaClient.create_messages(ctx.client, [
               %{topic_id: topic_a.id, payload: "6", payload_type: "text/plain"},
               %{topic_reference: topic_b.reference, payload: "baz", payload_type: "text/plain"}
             ])

    assert length(page_mixed.messages) == 2

    # grab message ids from mixed page
    assert [
             %{id: id8, topic_id: ^topic_a_id},
             %{id: _id9, topic_id: ^topic_b_id}
           ] = page_mixed.messages

    # check we can list per topic:
    assert {:ok, topic_b_page} = MoriaClient.list_messages(ctx.client, topic_b.id)
    assert length(topic_b_page.messages) == 3
    assert topic_b_page.topic.id == topic_b.id

    # pagination:
    assert {:ok, topic_a_page} = MoriaClient.list_messages(ctx.client, topic_a.id, first: 3)
    assert length(topic_a_page.messages) == 3
    assert topic_a_page.topic.id == topic_a.id
    assert topic_a_page.messages |> Enum.all?(fn m -> m.topic_id == topic_a.id end)
    # assert insert order is also listed order
    assert [id1, id2, id3] == Enum.map(topic_a_page.messages, & &1.id)

    # next page
    cursor = topic_a_page.page.end_cursor

    assert {:ok, paged_page} =
             MoriaClient.list_messages(ctx.client, topic_a.id, first: 3, after: cursor)

    # can stream messages via stream_messages/3
    assert [
             %{id: ^id1, topic_id: ^topic_a_id},
             %{id: ^id2, topic_id: ^topic_a_id},
             %{id: ^id3, topic_id: ^topic_a_id},
             %{id: ^id5, topic_id: ^topic_a_id},
             %{id: ^id6, topic_id: ^topic_a_id},
             %{id: ^id8, topic_id: ^topic_a_id}
           ] =
             MoriaClient.stream_messages!(ctx.client, topic_a.id, first: 10)
             |> Enum.to_list()

    # the final message should be on this page
    assert length(paged_page.messages) == 3
    assert [id5, id6, id8] == Enum.map(paged_page.messages, & &1.id)

    assert {:ok, page} =
             MoriaClient.list_messages(ctx.client, topic_a.id, first: 2, components: %{debug: ""})

    assert [
             %{components: %{"debug" => %{"errors" => [], "result" => _}}},
             %{components: %{"debug" => %{"errors" => [], "result" => _}}}
           ] = page.messages
  end
end
