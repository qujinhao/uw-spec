# JMeter 压测脚本模板

## 完整JMX脚本结构

```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0" jmeter="5.6.3">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="API性能测试计划" enabled="true">
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
    </TestPlan>
    <hashTree>
      <!-- 线程组 -->
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="{module}负载测试" enabled="true">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <stringProp name="LoopController.loops">${__P(loops,1)}</stringProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">${__P(threads,100)}</stringProp>
        <stringProp name="ThreadGroup.ramp_time">${__P(rampup,60)}</stringProp>
        <boolProp name="ThreadGroup.scheduler">true</boolProp>
        <stringProp name="ThreadGroup.duration">${__P(duration,300)}</stringProp>
      </ThreadGroup>
      <hashTree>
        <!-- HTTP默认值 -->
        <ConfigTestElement guiclass="HttpDefaultsGui" testclass="ConfigTestElement" testname="HTTP默认值" enabled="true">
          <stringProp name="HTTPSampler.domain">${__P(host,api.example.com)}</stringProp>
          <stringProp name="HTTPSampler.port">${__P(port,8080)}</stringProp>
          <stringProp name="HTTPSampler.protocol">${__P(protocol,https)}</stringProp>
        </ConfigTestElement>
        <hashTree/>

        <!-- HTTP Header Manager -->
        <HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="HTTP信息头" enabled="true">
          <collectionProp name="HeaderManager.headers">
            <elementProp name="" elementType="Header">
              <stringProp name="Header.name">Content-Type</stringProp>
              <stringProp name="Header.value">application/json</stringProp>
            </elementProp>
            <elementProp name="" elementType="Header">
              <stringProp name="Header.name">Authorization</stringProp>
              <stringProp name="Header.value">Bearer ${token}</stringProp>
            </elementProp>
          </collectionProp>
        </HeaderManager>
        <hashTree/>

        <!-- CSV Data Set Config -->
        <CSVDataSet guiclass="TestBeanGUI" testclass="CSVDataSet" testname="CSV数据" enabled="true">
          <stringProp name="delimiter">,</stringProp>
          <stringProp name="fileEncoding">UTF-8</stringProp>
          <stringProp name="filename">${__P(datafile,data/users.csv)}</stringProp>
          <boolProp name="ignoreFirstLine">true</boolProp>
          <boolProp name="recycle">true</boolProp>
          <stringProp name="shareMode">shareMode.all</stringProp>
          <stringProp name="variableNames">username,password</stringProp>
        </CSVDataSet>
        <hashTree/>

        <!-- 登录接口 -->
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="登录" enabled="true">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments">
              <elementProp name="" elementType="Argument">
                <stringProp name="Argument.name">username</stringProp>
                <stringProp name="Argument.value">${username}</stringProp>
              </elementProp>
              <elementProp name="" elementType="Argument">
                <stringProp name="Argument.name">password</stringProp>
                <stringProp name="Argument.value">${password}</stringProp>
              </elementProp>
            </collectionProp>
          </elementProp>
          <stringProp name="HTTPSampler.path">/api/auth/login</stringProp>
          <stringProp name="HTTPSampler.method">POST</stringProp>
        </HTTPSamplerProxy>
        <hashTree>
          <!-- JSON Extractor -->
          <JSONPostProcessor guiclass="JSONPostProcessorGui" testclass="JSONPostProcessor" testname="提取Token" enabled="true">
            <stringProp name="JSONPostProcessor.referenceNames">token</stringProp>
            <stringProp name="JSONPostProcessor.jsonPathExprs">$.data.token</stringProp>
            <stringProp name="JSONPostProcessor.match_numbers">1</stringProp>
          </JSONPostProcessor>
          <hashTree/>

          <!-- Response Assertion -->
          <ResponseAssertion guiclass="AssertionGui" testclass="ResponseAssertion" testname="状态码断言" enabled="true">
            <collectionProp name="Asserion.test_strings">
              <stringProp name="49586">200</stringProp>
            </collectionProp>
            <stringProp name="Assertion.test_field">Assertion.response_code</stringProp>
            <intProp name="Assertion.test_type">8</intProp>
          </ResponseAssertion>
          <hashTree/>
        </hashTree>

        <!-- 业务接口 -->
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="{业务接口名}" enabled="true">
          <boolProp name="HTTPSampler.postBodyRaw">true</boolProp>
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments">
              <elementProp name="" elementType="HTTPArgument">
                <stringProp name="Argument.value">{&quot;param&quot;:&quot;value&quot;}</stringProp>
              </elementProp>
            </collectionProp>
          </elementProp>
          <stringProp name="HTTPSampler.path">/api/v1/{endpoint}</stringProp>
          <stringProp name="HTTPSampler.method">POST</stringProp>
        </HTTPSamplerProxy>
        <hashTree>
          <!-- Duration Assertion -->
          <DurationAssertion guiclass="DurationAssertionGui" testclass="DurationAssertion" testname="响应时间断言" enabled="true">
            <stringProp name="DurationAssertion.duration">500</stringProp>
          </DurationAssertion>
          <hashTree/>
        </hashTree>

        <!-- Aggregate Report -->
        <ResultCollector guiclass="SummaryReport" testclass="ResultCollector" testname="汇总报告" enabled="true">
          <boolProp name="ResultCollector.error_logging">false</boolProp>
          <objProp>
            <name>saveConfig</name>
            <value class="SampleSaveConfiguration">
              <time>true</time>
              <latency>true</latency>
              <timestamp>true</timestamp>
              <success>true</success>
              <label>true</label>
              <code>true</code>
            </value>
          </objProp>
          <stringProp name="filename">${__P(reportdir,results)}/summary.csv</stringProp>
        </ResultCollector>
        <hashTree/>
      </hashTree>
    </hashTree>
  </hashTree>
</jmeterTestPlan>
```

## CSV 数据文件格式

```csv
username,password
user001,Pass@001
user002,Pass@002
user003,Pass@003
```

## JMeter 执行命令

```bash
jmeter -n -t load/{scenario}.jmx \
  -Jhost=api.example.com \
  -Jport=8080 \
  -Jprotocol=https \
  -Jthreads=100 \
  -Jrampup=60 \
  -Jduration=300 \
  -Jreportdir=results \
  -l results/{scenario}-YYMMDDHHMM.jtl \
  -e -o results/{scenario}-report-YYMMDDHHMM
```
