# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara/rails'

# Configure Capybara for system tests
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless

# Configure for Rails integration
if defined?(Rails)
  Capybara.app_host = 'http://localhost:3000'
  Capybara.server_host = 'localhost'
  Capybara.server_port = 3000
end

# Rack app for standalone testing
class DummyRackApp
  def call(env)
    request = Rack::Request.new(env)
    
    case request.path
    when '/test_streaming'
      [200, { 'Content-Type' => 'text/html' }, [
        '<div id="progress">Starting workflow...</div>',
        '<div id="result">Waiting for results...</div>',
        '<div id="turbo-stream-responses"></div>',
        '<script>',
        'setTimeout(() => {',
        '  document.getElementById("turbo-stream-responses").innerHTML = `',
        '    <turbo-stream action="replace" target="progress">',
        '      <template>Step 1 completed with test data</template>',
        '    </turbo-stream>',
        '    <turbo-stream action="replace" target="progress">',
        '      <template>Processing step 2...</template>',
        '    </turbo-stream>',
        '    <turbo-stream action="update" target="result">',
        '      <template><div class="success">All steps completed!</div></template>',
        '    </turbo-stream>',
        '  `;',
        '}, 100);',
        '</script>'
      ]]
    when '/test_concurrent'
      [200, { 'Content-Type' => 'text/html' }, [
        '<div id="workflow-1">Workflow 1 started</div>',
        '<div id="workflow-2">Workflow 2 started</div>',
        '<script>',
        'setTimeout(() => {',
        '  document.getElementById("workflow-1").textContent = "Workflow 1 completed";',
        '  document.getElementById("workflow-2").textContent = "Workflow 2 completed";',
        '}, 200);',
        '</script>'
      ]]
    when '/test_failing'
      [200, { 'Content-Type' => 'text/html' }, [
        '<div id="progress">Starting workflow...</div>',
        '<div id="errors"></div>',
        '<script>',
        'setTimeout(() => {',
        '  document.getElementById("errors").innerHTML = `',
        '    <turbo-stream action="replace" target="errors">',
        '      <template><div class="error">An error occurred during processing</div></template>',
        '    </turbo-stream>',
        '  `;',
        '}, 100);',
        '</script>'
      ]]
    when '/test_turbo_format'
      [200, { 'Content-Type' => 'text/vnd.turbo-stream.html' }, [
        '<turbo-stream action="replace" target="progress">',
        '  <template>Updated content</template>',
        '</turbo-stream>',
        '<turbo-stream action="update" target="result">',
        '  <template>Final result</template>',
        '</turbo-stream>'
      ]]
    when '/test_actions'
      [200, { 'Content-Type' => 'text/vnd.turbo-stream.html' }, [
        '<turbo-stream action="append" target="log">',
        '  <template>Log entry</template>',
        '</turbo-stream>',
        '<turbo-stream action="prepend" target="notifications">',
        '  <template>New notification</template>',
        '</turbo-stream>',
        '<turbo-stream action="remove" target="spinner">',
        '</turbo-stream>'
      ]]
    else
      [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
    end
  end
end

# Use dummy app for standalone testing
unless defined?(Rails)
  Capybara.app = DummyRackApp.new
end