# frozen_string_literal: true

require "minitest_helper"

module Fog
  module Parsers
    module AWS
      class Base < Fog::Parsers::Base
        def self.schema
          aws_schema.merge!(
            "ResponseMetadata" => {
              "RequestId" => :string
            }
          )
        end

        def self.aws_schema
          {}
        end

        def self.arrays
          ["member"]
        end

        def reset
          super
          @response["ResponseMetadata"] = {}
        end
      end
    end

    class SchemaTest < Minitest::Spec
      class ParserWrapper < Fog::Parsers::AWS::Base
        def input_xml
          raise NotImplementedError
        end

        def expected_output
          raise NotImplementedError
        end

        def perform_test
          @wrapper = Nokogiri::XML::SAX::Parser.new(self.class.new)
          @wrapper.parse(input_xml)
          @wrapper.document.response
        end
      end

      class RequestIdOnly < ParserWrapper
        def input_xml
          <<-XML
            <RequestResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
              <RequestResult>
                <Node1>
                  <String>string-value</String>
                </Node1>
              </RequestResult>
              <ResponseMetadata>
                <RequestId>9580fd15-d539-11e7-b50f-55c5aff10410</RequestId>
              </ResponseMetadata>
            </RequestResponse>
          XML
        end

        def expected_output
          {
            "ResponseMetadata" => {
              "RequestId" => "9580fd15-d539-11e7-b50f-55c5aff10410"
            },
          }
        end
      end

      describe RequestIdOnly do
        subject { RequestIdOnly.new }
        it { subject.perform_test.must_equal subject.expected_output }
      end

      class With1NodeOf4Values < ParserWrapper
        def self.aws_schema
          {
            "Node1" => {
              "String" => :string,
              "Timestamp" => :time,
              "Boolean" => :boolean,
              "Enum" => "Choice1|Choice2"
            },
          }
        end

        def input_xml
          <<-XML
            <RequestResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
              <RequestResult>
                <Node1>
                  <String>string-value</String>
                  <Timestamp>2017-11-20T22:15:01.632Z</Timestamp>
                  <Boolean>true</Boolean>
                  <Enum>Choice1</Enum>
                </Node1>
              </RequestResult>
              <ResponseMetadata>
                <RequestId>9580fd15-d539-11e7-b50f-55c5aff10410</RequestId>
              </ResponseMetadata>
            </RequestResponse>
          XML
        end

        def expected_output
          {
            "Node1" => {
              "String" => "string-value",
              "Timestamp" => Time.parse("2017-11-20T22:15:01.632Z"),
              "Boolean" => true,
              "Enum" => "Choice1",
            },
            "ResponseMetadata" => {
              "RequestId" => "9580fd15-d539-11e7-b50f-55c5aff10410"
            },
          }
        end
      end

      describe With1NodeOf4Values do
        subject { With1NodeOf4Values.new }
        it { subject.perform_test.must_equal subject.expected_output }
      end

      class With1NodeOf1ArrayOf3Values < ParserWrapper
        def self.aws_schema
          {
            "Node1" => [:string],
          }
        end

        def input_xml
          <<-XML
            <RequestResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
              <RequestResult>
                <Node1>
                  <member>string-value-1</member>
                  <member>string-value-2</member>
                  <member>string-value-3</member>
                 </Node1>
              </RequestResult>
              <ResponseMetadata>
                <RequestId>9580fd15-d539-11e7-b50f-55c5aff10410</RequestId>
              </ResponseMetadata>
            </RequestResponse>
          XML
        end

        def expected_output
          {
            "Node1" => [
              "string-value-1",
              "string-value-2",
              "string-value-3",
            ],
            "ResponseMetadata" => {
              "RequestId" => "9580fd15-d539-11e7-b50f-55c5aff10410"
            },
          }
        end
      end

      describe With1NodeOf1ArrayOf3Values do
        subject { With1NodeOf1ArrayOf3Values.new }
        it { subject.perform_test.must_equal subject.expected_output }
      end

      class With1NodeOf1ArrayOf2NodesOf1ValueAnd1Value < ParserWrapper
        def self.aws_schema
          {
            "Node1" => [{
              "String" => :string
            }],
            "Boolean" => :boolean
          }
        end

        def input_xml
          <<-XML
            <RequestResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
              <RequestResult>
                <Node1>
                  <member>
                    <String>string-value-1</String>
                  </member>
                  <member>
                    <String>string-value-2</String>
                  </member>
                </Node1>
                <Boolean>true</Boolean>
              </RequestResult>
              <ResponseMetadata>
                <RequestId>9580fd15-d539-11e7-b50f-55c5aff10410</RequestId>
              </ResponseMetadata>
            </RequestResponse>
          XML
        end

        def expected_output
          {
            "Node1" => [
              { "String" => "string-value-1" },
              { "String" => "string-value-2" },
            ],
            "Boolean" => true,
            "ResponseMetadata" => {
              "RequestId" => "9580fd15-d539-11e7-b50f-55c5aff10410"
            },
          }
        end
      end

      describe With1NodeOf1ArrayOf2NodesOf1ValueAnd1Value do
        subject { With1NodeOf1ArrayOf2NodesOf1ValueAnd1Value.new }
        it { subject.perform_test.must_equal subject.expected_output }
      end

      class DescribeActiveReceiptRuleSet < ParserWrapper
        def self.aws_schema
          {
            "Metadata" => {
              "Name" => :string,
              "CreatedTimestamp" => :time,
            },
            "Rules" => [{
              "Actions" => [{
                "AddHeaderAction" => {
                  "HeaderName" => :string,
                  "HeaderValue" => :string,
                },
                "BounceAction" => {
                  "Message" => :string,
                  "Sender" => :string,
                  "SmtpReplyCode" => :string,
                  "StatusCode" => :string,
                  "TopicArn" => :string,
                },
                "LambdaAction" => {
                  "FunctionArn" => :string,
                  "InvocationType" => "Event|RequestResponse",
                  "TopicArn" => :string,
                },
                "S3Action" => {
                  "BucketName" => :string,
                  "KmsKeyArn" => :string,
                  "ObjectKeyPrefix" => :string,
                  "TopicArn" => :string,
                },
                "SNSAction" => {
                  "Encoding" => "UTF-8|Base64",
                  "TopicArn" => :string,
                },
                "StopAction" => {
                  "Scope" => "RuleSet",
                  "TopicArn" => :string,
                },
                "WorkmailAction" => {
                  "OrganizationArn" => :string,
                  "TopicArn" => :string,
                },
              }],
              "Enabled" => :boolean,
              "Name" => :string,
              "Recipients" => [:string],
              "ScanEnabled" => :boolean,
              "TlsPolicy" => "Require|Optional",
            }]
          }
        end

        def input_xml
          <<-XML
            <DescribeActiveReceiptRuleSetResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
              <DescribeActiveReceiptRuleSetResult>
                <Metadata>
                  <Name>string-value-1</Name>
                  <CreatedTimestamp>2017-11-20T22:15:01.632Z</CreatedTimestamp>
                </Metadata>
                <Rules>
                  <member>
                    <Recipients>
                      <member>string-value-2</member>
                      <member>string-value-3</member>
                    </Recipients>
                    <Name>string-value-4</Name>
                    <TlsPolicy>Require</TlsPolicy>
                    <Actions>
                      <member>
                        <AddHeaderAction>
                          <HeaderValue>string-value-5</HeaderValue>
                          <HeaderName>string-value-6</HeaderName>
                        </AddHeaderAction>
                      </member>
                      <member>
                        <StopAction>
                          <Scope>RuleSet</Scope>
                        </StopAction>
                      </member>
                    </Actions>
                    <Enabled>true</Enabled>
                    <ScanEnabled>true</ScanEnabled>
                  </member>
                  <member>
                    <Recipients>
                      <member>string-value-7</member>
                    </Recipients>
                    <Name>string-value-8</Name>
                    <TlsPolicy>Optional</TlsPolicy>
                    <Actions>
                      <member>
                        <StopAction>
                          <Scope>RuleSet</Scope>
                        </StopAction>
                      </member>
                    </Actions>
                    <Enabled>false</Enabled>
                    <ScanEnabled>true</ScanEnabled>
                  </member>
                </Rules>
              </DescribeActiveReceiptRuleSetResult>
              <ResponseMetadata>
                <RequestId>9580fd15-d539-11e7-b50f-55c5aff10410</RequestId>
              </ResponseMetadata>
            </DescribeActiveReceiptRuleSetResponse>
          XML
        end

        def expected_output
          {
            "Metadata" => {
              "Name" => "string-value-1",
              "CreatedTimestamp" => Time.parse("2017-11-20T22:15:01.632Z"),
            },
            "Rules" => [
              {
                "Recipients" => [
                  "string-value-2",
                  "string-value-3",
                ],
                "Name" => "string-value-4",
                "TlsPolicy" => "Require",
                "Actions" => [
                  {
                    "AddHeaderAction" => {
                      "HeaderValue" => "string-value-5",
                      "HeaderName" => "string-value-6",
                    }
                  },
                  {
                    "StopAction" => {
                      "Scope" => "RuleSet"
                    }
                  }
                ],
                "Enabled" => true,
                "ScanEnabled" => true,
              },
              {
                "Recipients" => [
                  "string-value-7"
                ],
                "Name" => "string-value-8",
                "TlsPolicy" => "Optional",
                "Actions" => [
                  {
                    "StopAction" => {
                      "Scope" => "RuleSet"
                    }
                  }
                ],
                "Enabled" => false,
                "ScanEnabled" => true,
              }
            ],
            "ResponseMetadata" => {
              "RequestId" => "9580fd15-d539-11e7-b50f-55c5aff10410"
            },
          }
        end
      end

      describe DescribeActiveReceiptRuleSet do
        subject { DescribeActiveReceiptRuleSet.new }
        it { subject.perform_test.must_equal subject.expected_output }
      end
    end
  end
end
