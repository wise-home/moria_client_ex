# MoriaClient

API client for the Moria log storage service.
This code-base is useless without access to a Moria server.

## Installation

The package can be installed by adding `moria_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:moria_client, git: "https://github.com/wise-home/moria_client_ex.git", branch: "main", tag: "v0.35.1"},
  ]
end
```

## Usage

```elixir

client = MoriaClient.client(auth: {:bearer, my_token})

{:ok, namespaces_page} = MoriaClient.list_namespaces(client, first: 10)
```
