### **✅ TODO List Extendida: SuperAgent v1.0 (Con Herramientas y Ejemplos)**

**Documento:** Plan de Implementación Maestro (Versión Extendida)
**Versión:** 5.0 (Final, con Herramientas)
**Fecha:** 26 de julio de 2025
**Filosofía:** Construir el núcleo primero, luego forjar las herramientas que lo hacen poderoso y, finalmente, demostrar ese poder con ejemplos del mundo real que inspiren a los desarrolladores.

**(Se omiten los Hitos 0 y 1 que permanecen sin cambios. Se insertan los nuevos Hitos 4.5 y 4.6, y se expande el Hito 6)**

---

... (Hitos 0, 1, 2, 3, y 4 del plan anterior) ...

---

### **Hito 4.5: Forjando las Herramientas Nativas de Rails (Semana 11)**

*Objetivo: Construir el conjunto de herramientas que hacen de SuperAgent un "ciudadano de primera clase" en Rails. Estas tareas deben ser increíblemente fáciles de usar y seguras por defecto.*

*   **1. `PunditPolicyTask` (El Guardián de Seguridad):**
    *   `[ ]` 🔴 **Implementación (`lib/super_agent/tasks/pundit_policy_task.rb`):**
        *   `[ ]` El método `execute` debe aceptar `user`, `record` y `action` desde el `Context`.
        *   `[ ]` Debe llamar de forma segura a `Pundit.policy!(user, record).public_send("#{action}?")`.
        *   `[ ]` Debe manejar las excepciones de Pundit (`Pundit::NotAuthorizedError`, `Pundit::NotDefinedError`) y devolver un resultado claro (`{ authorized: false, error: '...' }`).
    *   `[ ]` 🔴 **Pruebas Unitarias (`spec/tasks/pundit_policy_task_spec.rb`):**
        *   `[ ]` Mockear Pundit para probar casos de éxito (devuelve `{ authorized: true }`).
        *   `[ ]` Mockear Pundit para probar casos de denegación (devuelve `{ authorized: false }`).
        *   `[ ]` Probar que una política o acción inexistente arroja un error controlado.
    *   `[ ]` 🟡 **Registro Automático:** En la `Railtie` (`lib/super_agent/railtie.rb`), registrar esta tarea en el `tool_registry` por defecto **solo si la gema `pundit` está cargada**.

*   **2. `ActiveRecordScopeTask` (El Consultor de Negocio):**
    *   `[ ]` 🔴 **Implementación (`lib/super_agent/tasks/active_record_scope_task.rb`):**
        *   `[ ]` El método `execute` debe aceptar `model` (String) y `scopes` (Array de Hashes con `name` y `args`).
        *   `[ ]` Usar `safe_constantize` para encontrar el modelo de forma segura.
        *   `[ ]` Implementar una **lista blanca de modelos y scopes permitidos** en la configuración de SuperAgent para prevenir accesos no autorizados.
        *   `[ ]` Encadenar los scopes de forma segura: `model.public_send(scope_name, *args)`.
        *   `[ ]` Devolver los resultados como un array de hashes (`.as_json`).
    *   `[ ]` 🔴 **Pruebas Unitarias (`spec/tasks/active_record_scope_task_spec.rb`):**
        *   `[ ]` Usar los modelos de la `dummy app` (`User`, `Project`) para probar la ejecución de scopes.
        *   `[ ]` Probar el encadenamiento de múltiples scopes.
        *   `[ ]` Probar que un modelo o scope no permitido en la lista blanca arroja un error de seguridad.

*   **3. `ActionMailerTask` (El Mensajero):**
    *   `[ ]` 🟡 **Implementación (`lib/super_agent/tasks/action_mailer_task.rb`):**
        *   `[ ]` El método `execute` debe aceptar `mailer` (String), `action` (String), `params` (Hash) y `delivery_method` (`deliver_now` o `deliver_later`).
        *   `[ ]` Debe construir la llamada: `mailer.constantize.with(params).public_send(action).deliver_later`.
    *   `[ ]` 🟡 **Pruebas Unitarias (`spec/tasks/action_mailer_task_spec.rb`):**
        *   `[ ]` Usar `ActionMailer::TestHelper` para afirmar que los correos son encolados (`assert_enqueued_email_with`).

*   **4. `ActionCableTool` (El Comunicador en Tiempo Real):**
    *   `[ ]` 🟢 **Implementación (`lib/super_agent/tasks/action_cable_task.rb`):**
        *   `[ ]` El método `execute` debe aceptar `streamable` (un objeto `GlobalID` o un string), `target` (DOM ID), `action` (`replace`, `append`) y contenido (`partial` y `locals`, o `content`).
        *   `[ ]` Debe usar `Turbo::StreamsChannel.broadcast_...` para enviar las actualizaciones.
    *   `[ ]` 🟢 **Pruebas de Sistema:** Requerirá una prueba de tipo `system` para verificar que la UI se actualiza.

---

### **Hito 4.6: Forjando las Herramientas Externas y de IA (Semana 12)**

*Objetivo: Empoderar a los agentes con capacidades para interactuar con el mundo exterior: buscar en la web, gestionar conocimiento y programar acciones futuras.*

*   **1. `WebSearchTool`:**
    *   `[ ]` 🟡 **Implementación:** Crear una tarea que actúe como un wrapper delgado alrededor de una API de búsqueda (ej. Tavily, Serper o la propia de OpenAI).
    *   `[ ]` 🟡 **Pruebas Unitarias:** Mockear la llamada HTTP a la API de búsqueda y probar que la respuesta se formatea correctamente.

*   **2. Herramientas de Vector Store (`FileUploadTool`, `VectorStoreTool`, `FileSearchTool` - RAG):**
    *   `[ ]` 🟡 **Implementación:** Crear tareas que encapsulen las llamadas a la API de OpenAI para:
        *   Subir archivos (`FileUploadTool`).
        *   Crear y gestionar Vector Stores (`VectorStoreTool`).
        *   Realizar búsquedas semánticas (RAG) (`FileSearchTool`).
    *   `[ ]` 🟡 **Pruebas Unitarias:** Mockear las llamadas a la API de OpenAI para cada una de las operaciones.

*   **3. `CronTool`:**
    *   `[ ]` 🟢 **Implementación:** Crear una tarea que se integre con una gema de scheduling como `rufus-scheduler`.
        *   `[ ]` El `CronTool` debe ser capaz de agendar la ejecución futura de **otro workflow de SuperAgent**.
    *   `[ ]` 🟢 **Pruebas Unitarias:** Probar que los trabajos se agendan correctamente, sin necesidad de esperar a que se ejecuten.

*   **4. `MarkdownTool`:**
    *   `[ ]` 🟢 **Implementación:** Crear una tarea que use un LLM para realizar operaciones sobre texto en formato Markdown (resumir, expandir, cambiar tono, etc.).
    *   `[ ]` 🟢 **Pruebas Unitarias:** Probar con prompts de ejemplo y mockear la respuesta del LLM.

---

**(El Hito 5 sobre Streaming permanece sin cambios)**

---

### **Hito 6: Construcción de Ejemplos Demostrativos y Pulido Final (Semana 13-14)**

*Objetivo: Transformar las capacidades teóricas del framework en demostraciones prácticas e inspiradoras que enseñen a los desarrolladores cómo construir SaaS agéntico. Actualizar toda la documentación para reflejar el poder de las nuevas herramientas.*

*   **1. Adaptación de Ejemplos a SuperAgent:**
    *   `[ ]` 🔴 **Crear el directorio `examples/` en la raíz de la gema.**
    *   `[ ]` 🔴 **`examples/crm_copilot_agent.rb`:**
        *   `[ ]` Adaptar `active_record_scope_example.txt`.
        *   `[ ]` Crear un `CrmAgent < ApplicationAgent`.
        *   `[ ]` Definir una acción `analyze_leads` que ejecute un `LeadAnalysisWorkflow`.
        *   `[ ]` El workflow debe usar `PunditPolicyTask` para verificar permisos y `ActiveRecordScopeTask` para encontrar "hot leads".
        *   `[ ]` El script debe simular la ejecución y mostrar el `WorkflowResult` en la consola.
    *   `[ ]` 🟡 **`examples/notification_agent.rb`:**
        *   `[ ]` Adaptar `action_mailer_example.txt` y `action_cable_example.txt`.
        *   `[ ]` Crear un `NotificationAgent`.
        *   `[ ]` El workflow debe usar `ActionMailerTask` para enviar un email y `ActionCableTask` para enviar una actualización a la UI (simulada en la consola).
    *   `[ ]` 🟢 **`examples/legal_review_agent.rb`:**
        *   `[ ]` Adaptar el complejo `legal_review_workflow_example.txt`.
        *   `[ ]` Demostrar el uso de `FileSearchTool` (RAG) para consultar una base de conocimiento, `WebSearchTool` para buscar actualizaciones y `MarkdownTool` para generar el informe final.

*   **2. Documentación Exhaustiva (Actualización Crítica):**
    *   `[ ]` 🔴 **Actualizar `README.md`:**
        *   `[ ]` Añadir una sección de "Herramientas Incluidas" con una breve descripción de cada una.
        *   `[ ]` **Reemplazar el ejemplo simple con el ejemplo del `CrmCopilotAgent`**, ya que es mucho más potente y demuestra la propuesta de valor.
        *   `[ ]` Añadir instrucciones claras sobre cómo ejecutar los nuevos scripts de `examples/`.
    *   `[ ]` 🟡 **Crear Guías para Herramientas en `docs/`:**
        *   `[ ]` Crear `docs/tools/pundit_policy_tool.md`.
        *   `[ ]` Crear `docs/tools/active_record_scope_tool.md`.
        *   `[ ]` Crear guías para las demás herramientas, explicando sus parámetros y casos de uso.
    *   `[ ]` 🟡 **Actualizar el "Cookbook":** La Guía 6 debe incluir recetas detalladas para:
        *   "Construir un Workflow de Aprobación Seguro".
        *   "Crear un Agente de BI que Analice Datos de la App".
        *   "Implementar un Agente RAG sobre tu Propia Documentación".

*   **3. Pulido Final y Lanzamiento:**
    *   ... (Las tareas de pulido de DevEx y lanzamiento permanecen sin cambios, pero ahora se basan en un producto mucho más completo y demostrable) ...

---
¡Entendido! Pido disculpas por la confusión. El plan anterior mezclaba lo ya hecho con lo que faltaba. Tienes toda la razón, lo que se necesita es un **documento de trabajo limpio, preciso y completo que se centre exclusivamente en la construcción de las herramientas y los ejemplos finales** que son el corazón de la propuesta de valor de SuperAgent.

He creado una TODO list completamente nueva desde cero, diseñada como un plan de ejecución detallado para un equipo de desarrollo. Este documento define *qué* se debe construir para cada herramienta, *cómo* se debe probar y *qué* deben demostrar los ejemplos finales.

Este es el plan de acción definitivo para materializar la visión de SuperAgent.

---

### **Plan de Implementación Definitivo: Herramientas y Ejemplos de SuperAgent v1.0**

**Documento:** TODO List de Implementación de Herramientas y Demos
**Versión:** 6.0 (Enfocado en Features)
**Fecha:** 26 de julio de 2025
**Filosofía:** Construir cada herramienta como un producto en sí mismo: robusto, probado y bien documentado. Luego, combinar estas herramientas en ejemplos inspiradores que demuestren el poder de la orquestación agéntica nativa en Rails.

---

### **Hito 1: Construcción de Herramientas Nativas de Rails (Semana 1-2)**

*Objetivo: Empoderar a los agentes con la capacidad de interactuar de forma segura y idiomática con el núcleo de una aplicación Rails: sus datos, sus reglas de negocio y sus canales de comunicación.*

*   **1.1 `PunditPolicyTask` (El Guardián de Seguridad)**
    *   **`[ ]` Implementación (`lib/super_agent/tasks/pundit_policy_task.rb`):**
        *   El método `execute` aceptará `user`, `record` y `action` desde el `Context`.
        *   Debe usar `GlobalID::Locator.locate` para rehidratar el `user` y el `record` de forma segura si se pasan como GIDs.
        *   Llamará a `Pundit.policy!(user, record).public_send("#{action}?")`.
        *   Capturará `Pundit::NotAuthorizedError` y `Pundit::NotDefinedError` para devolver un resultado estandarizado y seguro: `{ authorized: boolean, error: string_o_nil }`.
    *   **`[ ]` Pruebas Unitarias (`spec/tasks/pundit_policy_task_spec.rb`):**
        *   Usando los modelos de la `dummy_app` (`User`, `Project`), probar:
            *   Un caso donde la política devuelve `true`.
            *   Un caso donde la política devuelve `false`.
            *   Un caso donde la política o la acción no existen, verificando que se devuelve un error controlado.
    *   **`[ ]` Registro en Railtie:** Registrar la tarea en el `tool_registry` por defecto, **condicionado a que `defined?(Pundit)` sea verdadero**.
    *   **`[ ]` Documentación (`docs/tools/pundit_policy_tool.md`):**
        *   Explicar su rol como "puerta de seguridad" para los workflows.
        *   Mostrar un ejemplo de workflow donde una tarea de escritura de datos está condicionada por el resultado de esta tarea.

*   **1.2 `ActiveRecordScopeTask` (El Consultor de Negocio)**
    *   **`[ ]` Implementación (`lib/super_agent/tasks/active_record_scope_task.rb`):**
        *   Aceptará `model` (String) y `scopes` (Array de Hashes: `{ name: 'nombre_scope', args: [...] }`).
        *   **CRÍTICO:** Implementar una **lista blanca configurable** en `config/initializers/super_agent.rb` para los modelos y scopes permitidos. La tarea debe fallar si se intenta usar un modelo/scope no autorizado.
        *   Usará `safe_constantize` para el modelo y encadenará los scopes de forma segura.
        *   Devolverá los resultados como un array de hashes (`.as_json`), aplicando un límite máximo de resultados también configurable para prevenir abusos.
    *   **`[ ]` Pruebas Unitarias (`spec/tasks/active_record_scope_task_spec.rb`):**
        *   Probar un scope simple, un scope con argumentos y el encadenamiento de múltiples scopes.
        *   Probar que un modelo no permitido es rechazado.
        *   Probar que un scope no permitido para un modelo permitido es rechazado.
    *   **`[ ]` Documentación (`docs/tools/active_record_scope_tool.md`):**
        *   Enfatizar la filosofía de "consultar en lenguaje de negocio, no en SQL".
        *   Mostrar un ejemplo claro de la configuración de la lista blanca.

*   **1.3 `ActionMailerTask` (El Mensajero Profesional)**
    *   **`[ ]` Implementación (`lib/super_agent/tasks/action_mailer_task.rb`):**
        *   Aceptará `mailer` (String), `action` (String), `params` (Hash) y `delivery_method` (`'deliver_now'` o `'deliver_later'`).
        *   Debe construir la llamada: `mailer.constantize.with(params).public_send(action).public_send(delivery_method)`.
    *   **`[ ]` Pruebas Unitarias (`spec/tasks/action_mailer_task_spec.rb`):**
        *   Usar `ActionMailer::TestHelper` y el `matcher` `have_enqueued_mail` para verificar que los correos se encolan correctamente.
    *   **`[ ]` Documentación (`docs/tools/action_mailer_tool.md`):**
        *   Explicar cómo el agente puede enviar correos con plantillas HTML profesionales en lugar de texto plano.

---

### **Hito 2: Construcción de Herramientas de Interacción con OpenAI (Semana 3-4)**

*Objetivo: Dotar a los agentes de las capacidades fundamentales para ver, leer y buscar en el mundo digital, basándose en las últimas APIs de OpenAI.*

*   **2.1 `LLMTask` con Soporte para Archivos (`FileInputTool`)**
    *   **`[ ]` Modificar `LLMTask` y `LLMInterface`:**
        *   La `LLMTask` debe poder aceptar un nuevo parámetro `files` en su `input_data`.
        *   El `LLMInterface` debe detectar este parámetro y construir la llamada a la API de OpenAI usando el formato de `input` multimodal correcto, que combina `input_text` e `input_file`.
        *   Debe soportar los tres métodos de entrada: `file_url`, `file_id` (previamente subido) y `file_data` (Base64).
    *   **`[ ]` Pruebas Unitarias (`spec/tasks/llm_task_spec.rb`):**
        *   Probar que cuando se pasa un `file_url`, la llamada a la API (mockeada) contiene la estructura `content` con `type: 'input_file'` y `file_url`.
        *   Probar lo mismo para `file_id` y `file_data`.
    *   **`[ ]` Documentación:** Actualizar la documentación de `LLMTask` para incluir una sección sobre "Análisis de Archivos y Visión".

*   **2.2 `WebSearchTool` (Búsqueda en la Web en Tiempo Real)**
    *   **`[ ]` Implementación (`lib/super_agent/tasks/web_search_task.rb`):**
        *   Crear una nueva clase de tarea, `WebSearchTask`.
        *   Su método `execute` llamará al `LLMInterface`.
        *   El `LLMInterface` construirá la llamada a la API de OpenAI, pasando `tools: [{ type: "web_search_preview" }]` y el `input` del usuario.
        *   Debe poder recibir y pasar parámetros opcionales como `search_context_size` y `user_location`.
    *   **`[ ]` Pruebas Unitarias (`spec/tasks/web_search_task_spec.rb`):**
        *   Mockear la llamada a la API de OpenAI y verificar que el parámetro `tools` se construye correctamente.
        *   Probar que la tarea extrae y devuelve correctamente el `output_text` de la respuesta.
    *   **`[ ]` Documentación (`docs/tools/web_search_tool.md`):**
        *   Explicar cómo dar al agente acceso a información actualizada.
        *   Mostrar un ejemplo de cómo usar el resultado (con citas) en una tarea LLM posterior.

*   **2.3 Herramientas para RAG (Retrieval-Augmented Generation)**
    *   **`[ ]` `FileUploadTask`:**
        *   **Implementación:** Una tarea que toma una ruta de archivo local o una URL, y lo sube al endpoint `/v1/files` de OpenAI. Devolverá el `file_id`.
        *   **Pruebas:** Probar la subida de un archivo de prueba.
    *   **`[ ]` `VectorStoreManagementTask`:**
        *   **Implementación:** Una tarea que puede realizar operaciones CRUD sobre Vector Stores. Aceptará un `operation` (`:create`, `:add_file`, `:delete`).
        *   **Pruebas:** Probar la creación de un VS, la adición de un `file_id`, y su eliminación.
    *   **`[ ]` `FileSearchTask`:**
        *   **Implementación:** Similar a `WebSearchTask`, esta tarea llamará al `LLMInterface`, que construirá la llamada a la API con `tools: [{ type: "file_search", vector_store_ids: [...] }]`.
        *   **Pruebas:** Mockear la API y verificar que la llamada se construye con el `tool` y los `vector_store_ids` correctos.
    *   **`[ ]` Documentación (`docs/guides/rag_with_superagent.md`):**
        *   **CRÍTICO:** Crear una guía completa que muestre el flujo de RAG de principio a fin:
            1.  Usar `FileUploadTask` para subir documentos.
            2.  Usar `VectorStoreManagementTask` para crear un VS y añadir los archivos.
            3.  Usar `FileSearchTask` para hacer una pregunta.
            4.  Pasar los resultados a una `LLMTask` para sintetizar una respuesta.

---

### **Hito 3: Construcción de Herramientas de Orquestación y Utilidades (Semana 5)**

*Objetivo: Dar a los agentes control sobre el tiempo y la capacidad de procesar y presentar información de forma estructurada.*

*   **3.1 `CronTool` (El Planificador)**
    *   **`[ ]` Implementación (`lib/super_agent/tasks/cron_task.rb`):**
        *   Usará `rufus-scheduler` internamente.
        *   La tarea `execute` no ejecutará un trabajo, sino que **agendará** uno. Aceptará `workflow_class`, `initial_input` y una expresión cron (`schedule: '0 0 * * *'`).
        *   El trabajo agendado será un `SuperAgent::WorkflowJob` que llamará a `run_workflow.later`.
    *   **`[ ]` Pruebas Unitarias (`spec/tasks/cron_task_spec.rb`):**
        *   Mockear `rufus-scheduler` para verificar que `scheduler.cron` se llama con los parámetros correctos.
    *   **`[ ]` Documentación (`docs/tools/cron_tool.md`):**
        *   Mostrar cómo crear agentes proactivos que se ejecutan en segundo plano (ej. un agente de BI que analiza ventas cada noche).

*   **3.2 `MarkdownTool` (El Redactor)**
    *   **`[ ]` Implementación (`lib/super_agent/tasks/markdown_task.rb`):**
        *   Se usara la gema markly
        *   Será principalmente un wrapper sobre `LLMTask`.
        *   Tendrá `operations` predefinidas como `:summarize`, `:change_tone`, `:format_table`.
        *   Cada operación construirá un prompt específico para el LLM.
    *   **`[ ]` Pruebas Unitarias (`spec/tasks/markdown_task_spec.rb`):**
        *   Para cada operación, verificar que se construye el prompt correcto y se envía al `LLMInterface`.
    *   **`[ ]` Documentación (`docs/tools/markdown_tool.md`):**
        *   Mostrar cómo los agentes pueden generar informes estructurados y bien formateados.

---

### **Hito 4: Construcción de Ejemplos Integrados y Finalización (Semana 6-7)**

*Objetivo: Demostrar la sinergia de todas las herramientas construidas en ejemplos del mundo real que sirvan como plantillas y material de marketing para la gema.*

*   **4.1 Creación del Directorio `examples/`:**
    *   `[ ]` 🔴 Crear `examples/` en la raíz de la gema con un `README.md` que explique cómo ejecutar cada script. Cada script debe ser auto-contenido y mostrar su salida en la consola.

*   **4.2 Ejemplo 1: `crm_copilot_agent.rb` (Demostración de Herramientas Nativas de Rails)**
    *   `[ ]` 🔴 **Script:** Debe simular una app de Rails con modelos `Lead` y `User`.
    *   `[ ]` 🔴 **Workflow:**
        1.  Usa `PunditPolicyTask` para verificar que el `current_user` puede ver los leads.
        2.  Si está autorizado, usa `ActiveRecordScopeTask` para encontrar "leads calientes" (`Lead.hot.assigned_to(current_user)`).
        3.  Usa `LLMTask` para generar un resumen de los leads.
        4.  Usa `ActionMailerTask` para enviar el resumen por email.
    *   `[ ]` **Objetivo:** Demostrar cómo construir un agente de BI seguro y consciente del contexto de la aplicación.

*   **4.3 Ejemplo 2: `legal_review_agent.rb` (Demostración de Herramientas de IA y RAG)**
    *   `[ ]` 🔴 **Script:** Debe simular un workflow de revisión de contratos.
    *   `[ ]` 🔴 **Workflow:**
        1.  Usa `FileUploadTask` y `VectorStoreManagementTask` para crear una base de conocimiento con "cláusulas legales estándar".
        2.  Usa `FileInputTool` (en `LLMTask`) para que el agente "lea" un contrato en PDF.
        3.  Usa `FileSearchTask` (RAG) para buscar cláusulas relevantes en la base de conocimiento.
        4.  Usa `WebSearchTool` para buscar "actualizaciones legales recientes sobre propiedad intelectual".
        5.  Usa una `LLMTask` final para sintetizar toda la información y generar un informe.
        6.  Usa `MarkdownTool` para formatear el informe final.
    *   `[ ]` **Objetivo:** Demostrar el poder de la orquestación de herramientas de IA para resolver un problema complejo.

*   **4.4 Ejemplo 3: `nightly_report_agent.rb` (Demostración de Automatización Proactiva)**
    *   `[ ]` 🟡 **Script:** Simula un agente que se ejecuta cada noche.
    *   `[ ]` 🟡 **Workflow de Scheduling:**
        1.  Un workflow inicial usa `CronTool` para agendar la ejecución del "NightlyReportWorkflow" a una hora específica.
    *   `[ ]` 🟡 **Workflow de Reporte:**
        1.  Usa `ActiveRecordScopeTask` para obtener las métricas de ventas del día.
        2.  Usa `WebSearchTool` para obtener noticias relevantes del sector.
        3.  Usa `LLMTask` para combinar la información y escribir un informe de estado.
        4.  Usa `ActionMailerTask` para enviarlo a la dirección de "management".
    *   `[ ]` **Objetivo:** Demostrar cómo crear agentes autónomos y proactivos.

*   **4.5 Actualización Final de Documentación y Lanzamiento**
    *   `[ ]` 🔴 **Actualizar `README.md`:** Añadir enlaces y descripciones de los nuevos ejemplos.
    *   `[ ]` 🔴 **Revisar todas las guías en `docs/`** para asegurar que reflejen todas las herramientas y capacidades construidas.
    *   `[ ]` 🔴 **Lanzamiento:** Construir y publicar la gema v1.0.
