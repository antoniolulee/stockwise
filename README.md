# Shopify App Template - Ruby

This is a template for building a [Shopify app](https://shopify.dev/docs/apps/getting-started) using Ruby on Rails and React. It contains the basics for building a Shopify app.

Rather than cloning this repo, you can use your preferred package manager and the Shopify CLI with [these steps](#installing-the-template).

## Benefits

Shopify apps are built on a variety of Shopify tools to create a great merchant experience. The [create an app](https://shopify.dev/docs/apps/getting-started/create) tutorial in our developer documentation will guide you through creating a Shopify app using this template.

The Ruby app template comes with the following out-of-the-box functionality:

- OAuth: Installing the app and granting permissions
- GraphQL Admin API: Querying or mutating Shopify admin data
- REST Admin API: Resource classes to interact with the API
- Shopify-specific tooling:
  - AppBridge
  - Polaris
  - Webhooks

## Tech Stack

These third party tools are complemented by Shopify specific tools to ease app development:

| Tool | Usage |
|---------|---------|
| [Shopify App](https://github.com/Shopify/shopify_app) | Rails engine to help build Shopify app using Rails conventions. Helps to install your application on shops, and provides tools for: <li>OAuth</li><li>Session Storage</li><li>Webhook Processing</li><li>etc.</li> |
| [ShopifyAPI Gem](https://github.com/Shopify/shopify-api-ruby) | A lightweight gem to provide tools for: <br/><li>Obtaining an active session. (`ShopifyApp` uses this behind the scenes to handle OAuth)</li><li>Clients to make request to Shopify GraphQL and Rest APIs. See how it's used [here](#making-your-first-api-call)</li><li>Error handling</li><li>Application Logger</li><li>Webhook Management</li> |
| [App Bridge](https://shopify.dev/docs/apps/tools/app-bridge), </br>[App Bridge React](https://shopify.dev/docs/apps/tools/app-bridge/getting-started/using-react)| Frontend library that: <li>Add [authentication to API requests](https://shopify.dev/docs/api/app-bridge-library/apis/resource-fetching) in the frontend</li><li>Renders components outside of the App’s iFrame in Shopify's Admin page</li> |
| [Polaris React](https://polaris.shopify.com/) | A powerful design system and react component library that helps developers build high quality, consistent experiences for Shopify merchants. |
| [File-based routing](https://github.com/Shopify/shopify-frontend-template-react/blob/main/Routes.jsx) | Tool makes creating new pages easier. |
| [`@shopify/i18next-shopify`](https://github.com/Shopify/i18next-shopify) | A plugin for [`i18next`](https://www.i18next.com/) that allows translation files to follow the same JSON schema used by Shopify [app extensions](https://shopify.dev/docs/apps/checkout/best-practices/localizing-ui-extensions#how-it-works) and [themes](https://shopify.dev/docs/themes/architecture/locales/storefront-locale-files#usage). |

This template combines a number of third party open source tools:

- [Rails](https://rubyonrails.org/) builds the backend.
- [Vite](https://vitejs.dev/) builds the [React](https://reactjs.org/) frontend.
- [React Router](https://reactrouter.com/) is used for routing. We wrap this with file-based routing.
- [React Query](https://react-query.tanstack.com/) queries the Admin API.
- [`i18next`](https://www.i18next.com/) and related libraries are used to internationalize the frontend.
  - [`react-i18next`](https://react.i18next.com/) is used for React-specific i18n functionality.
  - [`i18next-resources-to-backend`](https://github.com/i18next/i18next-resources-to-backend) is used to dynamically load app translations.
  - [`@formatjs/intl-localematcher`](https://formatjs.io/docs/polyfills/intl-localematcher/) is used to match the user locale with supported app locales.
  - [`@formatjs/intl-locale`](https://formatjs.io/docs/polyfills/intl-locale) is used as a polyfill for [`Intl.Locale`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale) if necessary.
  - [`@formatjs/intl-pluralrules`](https://formatjs.io/docs/polyfills/intl-pluralrules) is used as a polyfill for [`Intl.PluralRules`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/PluralRules) if necessary.

> [!NOTE]
> If you'd prefer not to use React, you can [replace it with a Stimulus frontend](https://github.com/Shopify/shopify-app-template-ruby/wiki/Replacing-React-frontend-with-Stimulus).

## Getting started

### Requirements

1. You must [create a Shopify partner account](https://partners.shopify.com/signup) if you don’t have one.
1. You must create a store for testing if you don't have one, either a [development store](https://help.shopify.com/en/partners/dashboard/development-stores#create-a-development-store) or a [Shopify Plus sandbox store](https://help.shopify.com/en/partners/dashboard/managing-stores/plus-sandbox-store).
1. You must have [Ruby](https://www.ruby-lang.org/en/) installed.
1. You must have [Bundler](https://bundler.io/) installed.
1. You must have [Node.js](https://nodejs.org/) installed.

### Installing the template

This template runs on [Shopify CLI 3.0](https://shopify.dev/docs/apps/build/cli-for-apps). You can start a new project with this template by running this command:

```shell
shopify app init --template=https://github.com/Shopify/shopify-app-template-ruby
```

### Setting up your Rails app

Once the Shopify CLI clones the repo, you will be able to run commands on your app.
However, the CLI will not manage your Ruby dependencies automatically, so you will need to go through some steps to be able to run your app.
To make the process easier, the template provides a script to run the necessary steps:

1. Start off by switching to the `web` folder:

   ```shell
   cd web
   ```

2. Install the ruby dependencies:

   ```shell
   bundle install
   ```

3. Run the [Rails template](https://guides.rubyonrails.org/rails_application_templates.html) script.
   It will guide you through setting up your database and set up the necessary keys for encrypted credentials.

   ```shell
   bin/rails app:template LOCATION=./template.rb
   ```

And your Rails app is ready to run! You can now switch back to your app's root folder to continue:

```shell
cd ..
```

### Local Development

[The Shopify CLI](https://shopify.dev/docs/apps/build/cli-for-apps) connects to an app in your Partners dashboard.
It provides environment variables, runs commands in parallel, and updates application URLs for easier development.

You can develop locally by running the following command from the root of your app:

```shell
shopify app dev
```

Open the URL generated in your console. Once you grant permission to the app, you can start development.

## Deployment

### Application Storage

This template uses [Rails' ActiveRecord framework](https://guides.rubyonrails.org/active_record_basics.html) to store Shopify session data.
It provides migrations to create the necessary tables in your database, and it stores and loads session data from them.

The database that works best for you depends on the data your app needs and how it is queried.
You can run your database of choice on a server yourself or host it with a SaaS company.
Once you decide which database to use, you can configure your app to connect to it, and this template will start using that database for session storage.

### Build

The frontend is a single page React app.
It requires the `SHOPIFY_API_KEY` environment variable, which you can get by running `shopify app info --web-env`.
The CLI will set up the necessary environment variables for the build if you run its `build` command from your app's root:

In your app's root folder:

```shell
shopify app build --client-id=REPLACE_ME
```

The app build command will build both the frontend and backend when running as above.
If you're manually building (for instance when deploying the `web` folder to production), you'll need to build both of them:

```shell
cd web/frontend
SHOPIFY_API_KEY=REPLACE_ME shopify app build
cd ..
rake build:all
```

### Making your first API call

You can use the [ShopifyAPI](https://github.com/Shopify/shopify-api-ruby) gem to start make authenticated Shopify API calls.

- [Make a GraphQL Admin API call](https://github.com/Shopify/shopify-api-ruby/blob/main/docs/usage/graphql.md)
- [Make a GraphQL Storefront API call](https://github.com/Shopify/shopify-api-ruby/blob/main/docs/usage/graphql_storefront.md)
- [Make a Rest Admin API call](https://github.com/Shopify/shopify-api-ruby/blob/main/docs/usage/rest.md)

Examples from this app template:

- Making Admin **GraphQL** API request to create products:
  - `ProductCreator#create` (web/app/services/product_creator.rb)
- Making Admin **Rest** API request to count products:
  - `ProductsController#count` (web/app/controllers/products_controller.rb)

## Hosting

When you're ready to set up your app in production, you can follow [our deployment documentation](https://shopify.dev/docs/apps/deployment/web) to host your app on a cloud provider like [Heroku](https://www.heroku.com/) or [Fly.io](https://fly.io/).

When you reach the step for [setting up environment variables](https://shopify.dev/docs/apps/deployment/web#set-env-vars), you also need to set the following variables:

| Variable                   | Secret? | Required |     Value      | Description                                                 |
| -------------------------- | :-----: | :------: | :------------: | ----------------------------------------------------------- |
| `RAILS_MASTER_KEY`         |   Yes   |   Yes    |     string     | Use value from `web/config/master.key` or create a new one. |
| `RAILS_ENV`                |         |   Yes    | `"production"` |                                                             |
| `RAILS_SERVE_STATIC_FILES` |         |   Yes    |      `1`       | Tells rails to serve the React app from the public folder.  |
| `RAILS_LOG_TO_STDOUT`      |         |          |      `1`       | Tells rails to print out logs.                              |

## Known issues

### Hot module replacement and Firefox

When running the app with the CLI in development mode on Firefox, you might see your app constantly reloading when you access it.
That happened in previous versions of the CLI, because of the way HMR websocket requests work.

We fixed this issue with v3.4.0 of the CLI, so after updating it, you can make the following changes to your app's `web/frontend/vite.config.js` file:

1. Change the definition `hmrConfig` object to be:

   ```js
   const host = process.env.HOST
     ? process.env.HOST.replace(/https?:\/\//, "")
     : "localhost";

   let hmrConfig;
   if (host === "localhost") {
     hmrConfig = {
       protocol: "ws",
       host: "localhost",
       port: 64999,
       clientPort: 64999,
     };
   } else {
     hmrConfig = {
       protocol: "wss",
       host: host,
       port: process.env.FRONTEND_PORT,
       clientPort: 443,
     };
   }
   ```

1. Change the `server.host` setting in the configs to `"localhost"`:

   ```js
   server: {
     host: "localhost",
     ...
   ```

### I'm seeing "App couldn't be loaded" error due to browser cookies

- Ensure you're using the latest [shopify_app](https://github.com/Shopify/shopify_app/blob/main/README.md) gem that uses Session Tokens instead of cookies.
  - See ["My app is still using cookies to authenticate"](https://github.com/Shopify/shopify_app/blob/main/docs/Troubleshooting.md#my-app-is-still-using-cookies-to-authenticate)
- Ensure `shopify.app.toml` is present and contains up to date information for the app's redirect URLS. To reset/update this config, run

```shell
shopify app dev --reset
```

## Developer resources

- [Introduction to Shopify apps](https://shopify.dev/docs/apps/getting-started)
- [App authentication](https://shopify.dev/docs/apps/auth)
- [Shopify CLI](https://shopify.dev/docs/apps/tools/cli)
- [Shopify API Library documentation](https://github.com/Shopify/shopify-api-ruby/tree/main/docs)
- [Shopify App Gem](https://github.com/Shopify/shopify_app/blob/main/README.md)
- [Getting started with internationalizing your app](https://shopify.dev/docs/apps/best-practices/internationalization/getting-started)
  - [i18next](https://www.i18next.com/)
    - [Configuration options](https://www.i18next.com/overview/configuration-options)
  - [react-i18next](https://react.i18next.com/)
    - [`useTranslation` hook](https://react.i18next.com/latest/usetranslation-hook)
    - [`Trans` component usage with components array](https://react.i18next.com/latest/trans-component#alternative-usage-components-array)
  - [i18n-ally VS Code extension](https://marketplace.visualstudio.com/items?itemName=Lokalise.i18n-ally)




  ## Busines logic

  # Stockwise - Gestión Inteligente de Inventario para Shopify

## Resumen Ejecutivo

**Stockwise** es una aplicación SaaS diseñada para merchants de Shopify que necesitan un control preciso de su inventario. La aplicación previene rupturas de stock y exceso de inventario mediante alertas automáticas, dashboards visuales y predicciones basadas en datos históricos de ventas.

## Problema que Resuelve

Los merchants de Shopify enfrentan desafíos constantes con la gestión de inventario:
- **Rupturas de stock** que resultan en ventas perdidas
- **Exceso de inventario** que inmoviliza capital
- **Falta de visibilidad** sobre el estado real del inventario
- **Gestión manual** de umbrales por variante que consume tiempo

## Público Objetivo

- **Tiendas pequeñas y medianas** en Shopify
- **Merchants con múltiples variantes** que requieren control granular
- **Equipos con recursos limitados** que buscan automatización asequible

## Propuesta de Valor

### 1. Control Automático de Umbrales
- Configuración de umbrales mínimos por variante
- Cálculo automático de "salud del inventario": `((stock_actual - umbral_mínimo) / umbral_mínimo) × 100`
- Sin necesidad de etiquetado manual

### 2. Dashboard Visual de Inventario
- **Sistema de semáforo**: Verde (saludable) / Amarillo (atención) / Rojo (crítico)
- **Métricas de ventas**: Unidades vendidas en 2, 4 y 8 semanas
- **Recomendaciones**: Sugerencias para ajustar umbrales basadas en patrones de venta

### 3. Predicciones Inteligentes
- Forecasting de reposición basado en históricos de ventas
- Planificación de producción y reabastecimiento

## Objetivos de Impacto

- **80% reducción** en rupturas de stock
- **40% disminución** en exceso de inventario
- **20% tasa de adopción** en tiendas objetivo durante los primeros 6 meses

## Arquitectura de la Aplicación

### Modelos de Datos Principales

Variant:
- Product ID GID
- Variant ID GID
- Variant Title
- Tracked (boolean)
Belongs to shop
Has many InventoryLevels


Location:
- Shopify Location ID
- Shopify Location Name
Belongs to shop
Has many InventoryLevels


InventoryLevel:
- Shopify Location ID
- Shopify Product ID
- Shopify Variant ID
- Current stock (quantity)
- Minimum stock (quantity)
- Health percentage
Belongs to shop
Belongs to Item
Belongs to Location


## Tareas
Revisar las validaciones en los modelos location y variant
