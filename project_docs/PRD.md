De acuerdo. A partir de toda la información y la visión refinada, aquí tienes el Documento de Requisitos de Producto (PRD) final y completo para SuperAgent.

Este documento está diseñado para ser la única fuente de verdad sobre la visión, arquitectura y requisitos del framework, sin necesidad de consultar otros ficheros.

---

## **Documento de Requisitos de Producto (PRD): SuperAgent**

**Versión:** 4.0 (Final)
**Fecha:** 26 de julio de 2025
**Estado:** Visión de Arquitectura Definitiva

### **1. Título y Resumen Ejecutivo**

**Título:** **SuperAgent: El Framework para el SaaS Agéntico Nativo de Rails.**

**Resumen Ejecutivo:** SuperAgent es un framework de nueva generación para Ruby on Rails que fusiona una potente capa de **orquestación de workflows** (inspirada en `rdawn`) con una elegante capa de **interacción MVC** (inspirada en `Active Agent`). El resultado es una plataforma unificada y robusta para construir **SaaS Agéntico**: aplicaciones web que no solo responden a las acciones del usuario, sino que se convierten en socios proactivos y orientados a objetivos.

SuperAgent permite a los desarrolladores definir "Agentes" que actúan como controladores inteligentes, cuyas acciones son impulsadas por workflows robustos, explícitos, observables y seguros. Ofrece una experiencia de desarrollo "Rails-nativa" para la interacción del usuario y una arquitectura de workflows predecible y potente para la lógica de la IA, con un enfoque de primera clase en la depuración, la resiliencia y la seguridad.

### **2. Visión Filosófica y Principios de Diseño**

La creación de agentes de IA efectivos requiere resolver dos problemas: la **interacción** con el usuario y la **orquestación** de tareas complejas. SuperAgent se fundamenta en la fusión de ambas capas bajo los siguientes principios:

*   **Experiencia de Desarrollador (DevEx) Primero:** La complejidad inherente a la IA debe ser abstraída, no una carga adicional. Los generadores, los mensajes de error informativos y la documentación guiarán al desarrollador hacia las mejores prácticas desde el primer momento.
*   **Observabilidad por Defecto:** Los workflows de IA no deben ser cajas negras. Cada paso, cada entrada/salida y cada fallo deben ser registrados de forma estructurada y correlacionada. La depuración no es una ocurrencia tardía, es una característica central.
*   **Seguridad Integrada:** Los agentes manejan datos sensibles y se comunican con sistemas externos. El framework debe proporcionar herramientas nativas para mitigar riesgos como la fuga de datos y la inyección de prompts, integrándose de forma segura con mecanismos de autorización de Rails como Pundit.
*   **Resiliencia y Manejo de Errores:** Los servicios externos fallan. El framework debe ofrecer estrategias claras para reintentos, fallbacks y un manejo de errores que sea fácil de implementar tanto a nivel de workflow como de cara al usuario final.
*   **Extensibilidad Modular:** SuperAgent debe tener un núcleo sólido y herramientas nativas, pero su poder a largo plazo residirá en su ecosistema. Crear y registrar nuevas "Tareas" y "Herramientas" debe ser un proceso sencillo y bien documentado.

### **3. El Problema a Resolver**

*   **Limitaciones de `Active Agent` (o similar) en solitario:** Excelente para interacciones simples de un solo paso (pregunta -> LLM -> respuesta), pero carece de una estructura formal para orquestar cadenas de herramientas, lógica condicional y manejo de estado a largo plazo. Las acciones complejas se convierten en métodos monolíticos difíciles de mantener y depurar.
*   **Limitaciones de `rdawn` (o similar) en solitario:** Potente para la lógica de backend y los workflows, pero carece de una capa de presentación idiomática en Rails. Conectar los resultados de un workflow a la UI requiere una cantidad significativa de "plomería" manual (controladores, llamadas a Turbo Streams, etc.).

**La Solución de SuperAgent:** Proporciona un único y elegante punto de entrada (`Agent Action`) que desencadena un `Workflow` robusto, cuyos resultados (finales o intermedios) se canalizan de vuelta a la capa de interacción para ser renderizados al usuario de forma nativa, síncrona o asíncrona, y con capacidades de streaming en tiempo real.

### **4. Público Objetivo**

Desarrolladores de Ruby on Rails que desean construir aplicaciones con capacidades de IA complejas y multi-paso, sin abandonar las convenciones y la productividad del ecosistema Rails. El framework está dirigido tanto a desarrolladores experimentados que buscan una arquitectura limpia para la lógica de IA, como a aquellos que se inician en la IA y necesitan un andamiaje seguro y estructurado.

### **5. Arquitectura Central y Flujo de Datos**

1.  **`SuperAgent::Base < ActiveAgent::Base` (La Capa de Interacción):**
    *   La clase base de la que heredarán todos los agentes. Mantiene la familiaridad de definir acciones como métodos públicos.
    *   Proporciona acceso a un objeto `agent_context` que encapsula de forma segura la información del controlador (`current_user`, `request`, etc.).

2.  **El DSL `run_workflow` (El Puente):**
    *   Es el método central dentro de una acción de un agente. Se invoca de dos formas:
        *   `run_workflow(MyWorkflow, initial_input: {...})`: Ejecución síncrona.
        *   `run_workflow.later(MyWorkflow, initial_input: {...})`: Ejecución asíncrona a través de ActiveJob.
    *   Este método es responsable de instanciar el workflow, construir el contexto inicial de forma segura y invocar el motor de ejecución.

3.  **`SuperAgent::Context` (El Portador de Estado Seguro):**
    *   Un objeto de estado inmutable (basado en `Dry::Struct` o similar). Cada tarea recibe el contexto y devuelve un nuevo estado, previniendo efectos secundarios.
    *   **Fusión Segura:** El contexto se crea con una prioridad clara: `initial_input` tiene precedencia, seguido por el `agent_context`. Los `params` directos del controlador son tratados con desconfianza y deben ser pasados explícitamente.
    *   **Filtrado de Datos Sensibles:** El contexto tendrá un mecanismo (`private_keys`) para definir claves que **nunca** serán registradas en logs ni enviadas a LLMs, previniendo fugas de datos.

4.  **`SuperAgent::Workflow` (La Capa de Orquestación):**
    *   La clase base para definir la lógica de negocio en una serie de pasos (`steps`).
    *   Proporciona un DSL para definir cada `Task` (tarea), su entrada (mapeada desde el contexto) y la clave bajo la cual guardará su salida.

5.  **`SuperAgent::WorkflowEngine` (El Orquestador):**
    *   Recibe el `Workflow` y el `Context`.
    *   Genera un `workflow_execution_id` único para cada ejecución.
    *   Itera sobre las tareas, realizando las siguientes acciones en cada paso:
        1.  **Log (Inicio):** Registra el inicio de la tarea, etiquetado con el `workflow_execution_id`.
        2.  **Ejecución:** Llama a `task.execute(context)`. Gestiona reintentos si están configurados.
        3.  **Log (Fin):** Registra el resultado (éxito/fracaso), la duración y la salida, etiquetado con el mismo ID.
        4.  **Actualización de Contexto:** Fusiona el resultado de la tarea en una nueva instancia del contexto.
    *   En caso de fallo, detiene la ejecución, registra el error detallado y el estado del contexto en ese momento.

6.  **`SuperAgent::WorkflowResult` (El Objeto de Retorno):**
    *   Un objeto de valor que encapsula el resultado completo de una ejecución. Proporciona métodos amigables:
        *   `completed?` / `failed?`: Para un manejo condicional limpio.
        *   `output_for(:nombre_paso)`: Para acceder a la salida de un paso específico.
        *   `final_output`: Una convención para el resultado del último paso.
        *   `error_message` / `failed_task_name`: Para depurar y mostrar errores seguros al usuario.
        *   `full_trace`: Un historial completo de cada paso para auditoría.

7.  **Streaming y Asincronía:**
    *   **Streaming:** `run_workflow` puede aceptar un bloque. El `WorkflowEngine` hará `yield` en cada paso completado, pasando un objeto `StepResult` (`step_name`, `status`, `output`, `duration_ms`) que el agente puede usar para enviar actualizaciones a la UI en tiempo real vía `stream_update`.
    *   **Asincronía:** `run_workflow.later` encola un `SuperAgent::WorkflowJob`. Este job utiliza `GlobalID` para serializar los registros de ActiveRecord de forma segura. Opcionalmente, puede persistir el estado de la ejecución en un modelo `SuperAgent::Execution` para su seguimiento.

### **6. Experiencia del Desarrollador (DevEx)**

*   **Generadores de Código Holísticos:**
    *   `rails g super_agent:resource LeadAnalysis --actions=analyze,summarize` generará toda la estructura necesaria:
        *   `app/agents/lead_analysis_agent.rb` (con acciones de esqueleto).
        *   `app/workflows/lead_analysis/analyze_workflow.rb` y `summarize_workflow.rb`.
        *   `spec/agents/lead_analysis_agent_spec.rb` y `spec/workflows/...` con código de prueba de plantilla.
        *   Directorios de vistas y archivos de ejemplo.
*   **Depuración y Observabilidad:**
    *   Todos los logs de una ejecución de workflow estarán correlacionados por un `workflow_execution_id`, permitiendo un fácil seguimiento en sistemas como Datadog o grep.
    *   Los mensajes de error serán explícitos, indicando qué tarea falló y por qué.
*   **Herramientas Nativas Pre-registradas:**
    *   Un conjunto de tareas listas para usar que entienden el contexto de Rails: `PunditPolicyTask`, `ActiveRecordFindTask`, `ActionMailerTask`, `TurboStreamTask`.
*   **Descubrimiento:**
    *   Una tarea `rake super_agent:list_tasks` para que los desarrolladores puedan ver todas las herramientas disponibles en su aplicación.

### **7. Caso de Uso Detallado: Análisis de Leads en un CRM (End-to-End)**

1.  **Interfaz (Avo/Rails):** Un manager selecciona 3 leads y hace clic en la acción **"Analizar y Priorizar"**.

2.  **Capa de Interacción (`LeadAgent`):**
    *   La acción `analyze_and_prioritize` es invocada. Se genera un `request_id`.
    *   El agente llama a `run_workflow` pasándole la clase del workflow y la entrada inicial:
        ```ruby
        class LeadAnalysisAgent < SuperAgent::Base
          def analyze_and_prioritize(records:)
            # El bloque gestiona las actualizaciones en tiempo real
            run_workflow(LeadAnalysisWorkflow, initial_input: { leads: records }) do |step|
              stream_update(partial: "leads/progress", locals: { step: step })
            end

            # El resultado se usa para la respuesta final
            if result.completed?
              prompt(message: "Análisis completado", details: result.final_output)
            else
              prompt(alert: "Falló el análisis en el paso: #{result.failed_task_name}")
            end
          end
        end
        ```

3.  **Capa de Orquestación (`LeadAnalysisWorkflow`):**
    *   El `WorkflowEngine` inicia la ejecución, generando un `workflow_execution_id`.
    *   **Paso 1: `:authorize_action` (usa `PunditPolicyTask`):** Verifica que `current_user` puede analizar esos `leads`. Falla si no.
        *   *Yield:* `StepResult{name: :authorize_action, status: :success, ...}`
    *   **Paso 2: `:enrich_data` (usa `DirectHandlerTask`):** Itera sobre los leads (recibidos como `GlobalID` y rehidratados de forma segura) y busca datos relacionados en la BD.
        *   *Yield:* `StepResult{name: :enrich_data, status: :success, ...}`
    *   **Paso 3: `:analyze_sentiment` (usa `LLMTask`):** Envía los datos enriquecidos (filtrando claves privadas) a un LLM para obtener una puntuación.
        *   *Yield:* `StepResult{name: :analyze_sentiment, status: :success, ...}`
    *   **Paso 4: `:generate_summary` (usa `LLMTask`):** Genera un resumen ejecutivo final. Este será el `final_output` del workflow.
        *   *Yield:* `StepResult{name: :generate_summary, status: :success, ...}`

4.  **Vuelta a la Capa de Interacción:**
    *   El método `run_workflow` termina y devuelve el objeto `WorkflowResult`.
    *   La lógica condicional en el agente toma el control. Si `completed?` es `true`, renderiza el mensaje de éxito con los detalles del `final_output`. Si es `false`, muestra una alerta informando del paso que falló.

### **8. Requisitos No Funcionales**

*   **Rendimiento:** El overhead del framework para orquestar las tareas debe ser mínimo. Las operaciones deben ser eficientes en memoria, especialmente el manejo del contexto.
*   **Seguridad:** El filtrado de datos sensibles es un requisito crítico. La integración con mecanismos de autorización debe ser a prueba de fallos.
*   **Fiabilidad:** Las ejecuciones asíncronas deben ser resilientes a reinicios del servidor (gracias a ActiveJob y la persistencia opcional).
*   **Documentación:** La documentación debe ser exhaustiva, con guías para cada concepto principal y un "Cookbook" de recetas para patrones comunes.

### **9. Fuera del Alcance (para la v1.0)**

*   **UI de Administración de Workflows:** SuperAgent no proporcionará una interfaz gráfica para construir o monitorear workflows. Se centrará en la estructura de logging para permitir que herramientas de terceros lo hagan.
*   **Motor de Reglas de Negocio (BPMN):** No es un motor de procesos de negocio completo con bifurcaciones complejas y uniones. Es un orquestador de tareas secuenciales con manejo de errores.
*   **Componentes de UI:** No se proporcionarán componentes de UI pre-construidos (como un chat), aunque la documentación podría incluir ejemplos de cómo construirlos.

### **10. Conclusión**

SuperAgent no es solo una fusión de dos librerías; es la materialización de una nueva forma de construir software en Rails. Al unificar la **interacción** y la **orquestación** bajo principios de **robustez, observabilidad y una DevEx superior**, SuperAgent empodera a los desarrolladores para construir la próxima generación de SaaS: aplicaciones que no solo almacenan y presentan datos, sino que **razonan, actúan y colaboran** como verdaderos miembros del equipo.
