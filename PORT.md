# Port

Port is a research tool that will enable individuals to donate their digital trace data to academic research in a secure, transparent, and privacy-protecting manner. 

## Digital Data Donation Infrastructure (D3I)

The D3i project is funded by PDI-SSH and is a collaboration between six Dutch universities and Eyra.

The consortium is composed by researchers from:

* University of Amsterdam
* Radboud University 
* VU Amsterdam
* Utrecht University
* Tilburg University
* Erasmus University Rotterdam

## D3i Pilot

The first phase of the project (ended in december 2022) resulted in a MVP solution to run one Port app on top of a Next bundle. This Next + Port combi can be released as a Docker image and deployed on [Azure Web App Service](https://azure.microsoft.com/en-us/products/app-service/web).

## Development setup instructions

0. Pre-requisite

    * Install [asdf](https://asdf-vm.com) 
    * Install [PostgreSQL Server](https://www.postgresql.org) 
    * Fork and clone branch `d3i/latest` of this repo.

1. Create a PostgreSQL database and replace the configurated values in `core/config/dev.exs` with your own:

    ```Elixir
    # Configure your database
    config :core, Core.Repo,
    username: "postgres",
    password: "postgres",
    database: "next_dev",
    ```

2. Link Port app in `core/assets/package.json`

    See https://github.com/eyra/port-poc/blob/master/README.md on how to create your own Port app.

    Go to [package.json](core/assets/package.json) qne 4eplace `github:eyra/port` with a reference to your Port app. 

3. Install tools:

    ```sh
    $ asdf plugin-add erlang
    $ asdf plugin-add elixir
    $ asdf plugin-add nodejs

    $ asdf install
    ```

    See `.tool-versions` for the exact versions that will be installed

4. Install dependencies:
    ```sh
    $ cd core
    $ make install
    ```

5. Build Next (from core folder):

    ```sh
    $ BUNDLE=next make build
    ```

6. Run database migrations  (from core folder)

    ```sh
    $ mix ecto.migrate
    ```

7. Run Next locally (from core folder):

    ```sh
    $ BUNDLE=next make run
    ```

8. Go to browser

    The Port app is running at: http://localhost:4000/data-donation/port. To start a donation session complete the url with:

    * App id (aka flow id). Currently we have only one Port app running with id `1`.
    * Participant id. Can be any alpha numeric string).

    Example: http://localhost:4000/data-donation/port/1/tester1

## Port integration code

| Source file  | Description |
| ------------- | ------------- |
| [port.js](core/assets/js/port.js)  | Javascript hook  responsble for starting the Port app and implementing the Port app `System` callback interface |
| [port_page.ex](core/systems/data_donation/port_page.ex) | Elixir/Phoenix web page running on endpoint `/data-donation/port/:appid/:participantid` |
| [port_model.ex](core/systems/data_donation/port_model.ex)  | Port app configuration (id and storage configuration) |
| [port_model_data.ex](core/systems/data_donation/port_model_data.ex)  | Contains configuration for Port app with id `1` |
| [delivery.ex](core/systems/data_donation/delivery.ex)  | Asynchronious delivery of donated data backend by [Oban](https://hexdocs.pm/oban/Oban.html) |
| [azure_storage_backend.ex](core/systems/data_donation/azure_storage_backend.ex)  | Integration with [Azure Blob Storage](https://azure.microsoft.com/en-us/products/storage/blobs/#overview). |


## Port rate limiters

To prevent users from exhausting system resources Next makes use of rate limiters. The local configuration for rate limiters for Azure Blob Service can be found in `core/config/dev.exs`:

```Elixir
config :core, :rate,
  prune_interval: 5 * 1000,
  quotas: [
    [service: :azure_blob, limit: 1, unit: :call, window: :second, scope: :local],
    [service: :azure_blob, limit: 100, unit: :byte, window: :second, scope: :local]
  ]
```

.. and the production configuration can be found in `core/config/config.exs`:

```Elixir
config :core, :rate,
  prune_interval: 60 * 60 * 1000,
  quotas: [
    [service: :azure_blob, limit: 1000, unit: :call, window: :minute, scope: :local],
    [service: :azure_blob, limit: 10_000_000, unit: :byte, window: :day, scope: :local],
    [service: :azure_blob, limit: 1_000_000_000, unit: :byte, window: :day, scope: :global]
  ]
```

## Release instructions

1. Create a Docker image

```sh
$ cd core
$ docker build  --build-arg VERSION=1.0.0 --build-arg BUNDLE=next . -t next:latest
$ docker image save next -o next.zip
```

2. Running the Docker image

Several environment variables are required for running:

* BUNDLE_DOMAIN=<domain name>
* DB_USER=<db-credentials>
* DB_PASS=<db-credentials>
* DB_HOST=<db-host>
* DB_NAME=<db-name>
* SECRET_KEY_BASE=<a-random-sequence-of-letters-and-numbers>
* AZURE_BLOB_CONTAINER=<blob-container>
* AZURE_BLOB_STORAGE_USER=<blob-account-name>
* AZURE_SAS_TOKEN=<sas-token>
* STATIC_PATH=/static
* SSL_DISABLED=true
