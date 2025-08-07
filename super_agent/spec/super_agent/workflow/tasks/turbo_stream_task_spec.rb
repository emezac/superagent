# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuperAgent::Workflow::Tasks::TurboStreamTask do
  let(:context) { SuperAgent::Workflow::Context.new(user_name: "Alice", project_name: "MyProject") }
  let(:task) { described_class.new(options) }

  describe "basic functionality" do
    let(:options) do
      {
        target: "#progress",
        action: "replace",
        content: "Processing {{user_name}}'s {{project_name}}..."
      }
    end

    it "interpolates template variables" do
      result = task.execute(context)
      expect(result[:content]).to include("Alice's MyProject")
    end

    it "returns structured result" do
      result = task.execute(context)
      expect(result[:action]).to eq("replace")
      expect(result[:target]).to eq("#progress")
    end
  end

  describe "with different actions" do
    let(:context) { SuperAgent::Workflow::Context.new(message: "Hello World") }

    it "supports append action" do
      task = described_class.new(
        target: "#messages",
        action: "append",
        content: "{{message}}"
      )
      
      result = task.execute(context)
      expect(result[:action]).to eq("append")
      expect(result[:content]).to eq("Hello World")
    end

    it "supports remove action" do
      task = described_class.new(
        target: "#loading",
        action: "remove"
      )
      
      result = task.execute(context)
      expect(result[:action]).to eq("remove")
      expect(result[:target]).to eq("#loading")
    end
  end

  describe "error handling" do
    it "raises error for unknown action" do
      task = described_class.new(
        target: "#test",
        action: "invalid_action"
      )

      expect { task.execute(context) }.to raise_error(ArgumentError)
    end

    it "requires content, template, or partial" do
      task = described_class.new(
        target: "#test",
        action: "replace"
      )

      expect { task.execute(context) }.to raise_error(ArgumentError)
    end
  end
end