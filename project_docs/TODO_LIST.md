### ✅ **TODO List Detallada: Proyecto SuperAgent**

**Filosofía:** Cada nueva línea de código de implementación debe ir acompañada de una nueva línea de código de prueba. El entorno de pruebas principal será una aplicación Rails "dummy" configurada con las dependencias clave (Avo, Devise, Pundit, etc.).

**Leyenda de Prioridades:**
*   🔴 **Crítico:** Fundamental para la funcionalidad del hito. No se puede avanzar sin esto.
*   🟡 **Importante:** Necesario para una característica completa.
*   🟢 **Deseable:** Mejora la calidad o la experiencia del desarrollador (DevEx).

---

### **Milestone 0: Fundación, Configuración y Arnés de Pruebas (Semana 1-2)**

*Objetivo: Preparar un entorno de desarrollo y pruebas a prueba de balas antes de escribir la lógica principal.*

*   **1. Infraestructura de la Gema:**
    *   `[ ]` 🔴 Crear la estructura de la gema `super_agent` con `bundle gem super_agent`.
    *   `[ ]` 🔴 Definir las dependencias en `super_agent.gemspec`:
        *   Runtime: `rails (>= 7.1)`, `activesupport`, `activejob`, `zeitwerk`, `ruby-openai`, `httpx`.
        *   Desarrollo: `rspec-rails`, `factory_bot_rails`, `rubocop-rails`, `pry-rails`, `sqlite3`.
    *   `[ ]` 🔴 Configurar Zeitwerk en el punto de entrada de la gema (`lib/super_agent.rb`) para la carga de clases.

*   **2. Aplicación de Pruebas (Dummy App):**
    *   `[ ]` 🔴 Crear una aplicación Rails de prueba en `spec/dummy`.
    *   `[ ]` 🔴 Configurar la dummy app para que cargue la gema `super_agent` desde el directorio local.
    *   `[ ]` 🔴 Añadir dependencias clave a la dummy app: `avo`, `devise`, `pundit`, `good_job` (para pruebas de `ActiveJob`).
    *   `[ ]` 🔴 Crear modelos básicos en la dummy app: `User`, `Project`, `Task`, con sus factorías de FactoryBot.
    *   `[ ]` 🔴 Configurar Avo, Devise y Pundit en la dummy app con políticas y recursos básicos. Esto es **crítico** para las pruebas de integración.

*   **3. Configuración de Pruebas (RSpec):**
    *   `[ ]` 🔴 Configurar RSpec para que cargue el entorno de la dummy app.
    *   `[ ]` 🟡 Crear helpers de RSpec para iniciar sesión con Devise (`sign_in(user)`).
    *   `[ ]` 🟡 Crear un helper `TestHarness` para facilitar la prueba de workflows, permitiendo mockear respuestas de LLM y herramientas.

*   **4. CI / Calidad de Código:**
    *   `[ ]` 🟡 Configurar GitHub Actions para ejecutar RSpec y RuboCop en cada push.
    *   `[ ]` 🟡 Establecer una configuración de RuboCop estricta.

---

### **Milestone 1: El Generador de Instalación y la Configuración Central (Semana 3)**

*Objetivo: Asegurar que la gema se pueda instalar y configurar en una aplicación Rails de forma impecable y predecible.*

*   **1. Implementación del Generador de Instalación:**
    *   `[ ]` 🔴 Crear `lib/generators/super_agent/install/install_generator.rb`.
    *   `[ ]` 🔴 El generador debe realizar las siguientes acciones:
        1.  Copiar un archivo de inicialización a `config/initializers/super_agent.rb`.
        2.  Crear los directorios `app/agents`, `app/workflows` y `app/views/agents` si no existen.
        3.  Crear un `ApplicationAgent` y `ApplicationWorkflow` base en sus respectivos directorios.
        4.  (Opcional) Ofrecer añadir una ruta en `config/routes.rb` para un futuro dashboard de SuperAgent.

*   **2. Implementación del Sistema de Configuración:**
    *   `[ ]` 🔴 Crear `lib/super_agent/configuration.rb`.
    *   `[ ]` 🔴 Definir opciones de configuración: `api_key`, `default_model`, `logger`, etc.
    *   `[ ]` 🔴 Asegurar que el inicializador (`config/initializers/super_agent.rb`) configure estas opciones.

*   **3. Pruebas del Generador:**
    *   `[ ]` 🔴 **Prueba de Archivos:** Escribir una prueba de generador que ejecute `rails g super_agent:install` en la dummy app y verifique:
        *   Que el archivo `config/initializers/super_agent.rb` existe y su contenido es el esperado.
        *   Que los directorios `app/agents` y `app/workflows` han sido creados.
        *   Que los archivos `app/agents/application_agent.rb` y `app/workflows/application_workflow.rb` existen.
    *   `[ ]` 🟡 **Prueba de Idempotencia:** Asegurarse de que ejecutar el generador dos veces no cause errores.

---

### **Milestone 2: Fusión del Core y Flujo Básico (Semana 4-6)**

*Objetivo: Lograr que una acción de un Agente pueda invocar un Workflow simple y devolver un resultado.*

*   **1. Clases Base y DSL:**
    *   `[ ]` 🔴 Implementar `SuperAgent::Base < ActiveAgent::Base`.
    *   `[ ]` 🔴 Implementar `SuperAgent::Workflow < rdawn::Workflow` (o su equivalente lógico).
    *   `[ ]` 🔴 Implementar el DSL `run_workflow(WorkflowClass, initial_input: {})` dentro de `SuperAgent::Base`.
    *   `[ ]` 🔴 Definir `WorkflowResult` para estandarizar la salida de `run_workflow`.

*   **2. Generador de Recursos:**
    *   `[ ]` 🟡 Crear `lib/generators/super_agent/resource/resource_generator.rb`.
    *   `[ ]` 🟡 Debe generar:
        *   `app/agents/[resource_name]_agent.rb`.
        *   `app/workflows/[resource_name]_workflow.rb`.
        *   `app/views/agents/[resource_name]_agent/`.

*   **3. Pruebas de Unidad e Integración:**
    *   `[ ]` 🔴 **Prueba de Unidad (`SuperAgent::Base`):** Testear el método `run_workflow`, mockeando la ejecución del workflow y verificando que devuelve un `WorkflowResult` correcto.
    *   `[ ]` 🔴 **Prueba de Integración (Flujo Completo):**
        1.  Definir un `TestAgent` y un `TestWorkflow` simple (ej. una tarea `DirectHandlerTask` que duplique un número).
        2.  Instanciar el `TestAgent`.
        3.  Llamar a la acción del agente.
        4.  Verificar que el workflow se ejecutó y que la acción devolvió el resultado esperado.
    *   `[ ]` 🔴 **Prueba del Generador `resource`:** Similar a la del generador `install`, verificar que se creen todos los archivos y directorios correctamente.

---

### **Milestone 3: Herramientas Nativas de Rails y Asincronía (Semana 7-9)**

*Objetivo: Dotar a los workflows de la capacidad de interactuar de forma segura y eficiente con el resto de la aplicación Rails.*

*   **1. Implementación de Herramientas Nativas:**
    *   `[ ]` 🔴 **`ActiveRecordScopeTool`:** Implementar la lógica para ejecutar scopes de forma segura.
    *   `[ ]` 🔴 **`PunditPolicyTool`:** Implementar la lógica para verificar permisos.
    *   `[ ]` 🔴 **`ActionMailerTool`:** Implementar la lógica para enviar correos.
    *   `[ ]` 🟡 **`ActionCableTool (TurboStreamTool)`:** Implementar la lógica para enviar actualizaciones a la UI.
    *   `[ ]` 🔴 Registrar automáticamente estas herramientas en el `ToolRegistry` al iniciar Rails.

*   **2. Integración con `ActiveJob`:**
    *   `[ ]` 🔴 Añadir un método `run_workflow.later(WorkflowClass, initial_input: {})` al DSL.
    *   `[ ]` 🔴 Crear un `SuperAgent::WorkflowJob < ApplicationJob` que se encargue de la ejecución.
    *   `[ ]` 🟡 **Serialización:** Usar `GlobalID` para pasar `ActiveRecord` objects al job de forma segura.

*   **3. Pruebas Exhaustivas:**
    *   `[ ]` 🔴 **Pruebas de Unidad para cada Herramienta:**
        *   `ActiveRecordScopeTool`: Probar con scopes reales en los modelos de la dummy app. Probar la seguridad (intentar llamar a un scope no permitido).
        *   `PunditPolicyTool`: Probar con políticas y usuarios reales de la dummy app. Probar casos de éxito y de denegación de permiso.
        *   `ActionMailerTool`: Usar `ActionMailer::TestHelper` para verificar que los correos se encolan o envían correctamente.
        *   `ActionCableTool`: Mockear `Turbo::StreamsChannel` para verificar que se llame a `broadcast_render_to`.
    *   `[ ]` 🔴 **Pruebas de Integración con `ActiveJob`:**
        *   Ejecutar `run_workflow.later`.
        *   Usar los helpers de `ActiveJob::TestHelper` (`assert_enqueued_with`, `perform_enqueued_jobs`).
        *   Verificar que el workflow se ejecuta correctamente en segundo plano.
        *   Verificar que los `ActiveRecord` objects se serializan y deserializan correctamente con `GlobalID`.

---

### **Milestone 4: Interacción en Tiempo Real y UI (Semana 10-12)**

*Objetivo: Crear una experiencia de usuario fluida, donde el progreso del workflow se refleje en la UI en tiempo real.*

*   **1. Streaming del Workflow:**
    *   `[ ]` 🔴 Modificar el `WorkflowEngine` para que pueda aceptar un bloque y hacer `yield` con el resultado de cada tarea (`StepResult`).
    *   `[ ]` 🔴 Modificar `run_workflow` en `SuperAgent::Base` para que pase este bloque al motor.

*   **2. Integración con `ActionCableTool`:**
    *   `[ ]` 🔴 Dentro del bloque de `run_workflow`, usar `stream_update` (un método de `Active Agent`) que internamente usa `ActionCableTool` para enviar un `Turbo Stream` a la UI.

*   **3. Componente de UI Pre-construido (Opcional, para Avo):**
    *   `[ ]` 🟡 Crear un `Avo::Tool` de panel de chat.
    *   `[ ]` 🟡 El frontend usará Stimulus y se conectará a un `ActionCable::Channel`.
    *   `[ ]` 🟡 El backend del chat invocará al agente y usará el streaming para las respuestas.

*   **4. Pruebas:**
    *   `[ ]` 🔴 **Prueba de Integración de Streaming:**
        1.  Crear un workflow de varios pasos.
        2.  Ejecutarlo con `run_workflow` y un bloque.
        3.  Dentro del bloque, registrar las actualizaciones en un array.
        4.  Verificar que el bloque se llamó el número correcto de veces y con los datos esperados de cada paso.
    *   `[ ]` 🟡 **Prueba de Sistema (con Capybara):**
        1.  En la dummy app, crear una página que inicie un workflow con streaming.
        2.  Usar Capybara para simular la acción del usuario.
        3.  Verificar que los `Turbo Stream` actualizan el DOM de la página en tiempo real con los mensajes de progreso.

### **Milestone 5: Pulido, Documentación y Lanzamiento (Semana 13-14)**

*Objetivo: Empaquetar todo en una gema de alta calidad, fácil de usar y bien documentada.*

*   **1. Documentación:**
    *   `[ ]` 🔴 Escribir un `README.md` completo.
    *   `[ ]` 🔴 Crear guías detalladas en un directorio `docs/`:
        *   Guía de Instalación y Configuración.
        *   Guía de Creación de Agentes y Workflows.
        *   Guía de Uso de Herramientas Nativas.
        *   Guía de Interacción en Tiempo Real.
    *   `[ ]` 🟡 Usar YARD para documentar la API pública del código.

*   **2. Pulido Final:**
    *   `[ ]` 🔴 Revisar todos los mensajes de error para que sean claros y útiles para el desarrollador.
    *   `[ ]` 🔴 Ejecutar toda la suite de pruebas una última vez.
    *   `[ ]` 🟢 Crear una aplicación de demostración completa.

*   **3. Lanzamiento:**
    *   `[ ]` 🔴 Revisar y finalizar el `super_agent.gemspec`.
    *   `[ ]` 🔴 Construir la gema (`gem build`).
    *   `[ ]` 🔴 Publicar la versión 1.0.0 en RubyGems.org.
