---
layout: post
authors: Hugo Fernandes, José Ferreira, Sofia Gomes, Elaine Navalho, João Ventura
title: From Manual to Automatic
---

In the more recent years the interest on test automation has been increased significantly. Some of the reasons behind this growth include a greater need for faster software delivery processes, increased productivity and cost/effort reduction associated to the tests itself. This article will focus on test automation, its advantages and drawbacks and when and how should the transition from manual to automatic be made. 
The article will also provide some examples of test automation tools, programming languages used for test automation and continuous integration software.

## How vital is test automation in today’s world. 

We live in a digital age. Every day new applications are deployed in productions systems and product features are improved, adjusted and updated with the objective of promoting the same products in an increasingly competitive market.
The balance between shorter development cycles, more challenging *time to market* times and quality delivery is nowadays put to the test more than ever. Taking this into mind, many software firms have started to adopt automation methodologies to reduce time and money. In software testing the test automation promotes three significant benefits <sup>[1]</sup>: 

- Cumulative coverage of previously developed features, increasing defect detection and reducing bug fixing costs; 
- Reproducibility by ensuring software stability and reduced market times and costs; 
- More effective resource management, resulting in increased productivity. 

To better demonstrate the advantages of test automation when compared to manual testing, our team conducted a basic study with five manual and automatic tests on an internal prototype webapp. As provided in the Appendix I of this article, it has been considered the average metrics for the human resources effort costs for implementing both the manual tests and the automation tests. Because it has been assumed that the maintenance costs were equivalent in both approaches, it has been decided that these were not to be included in the study.
Automation scripting times were considerably higher than manual test specification, but get progressively this starting discrepancy has been diluted as the number of test executions cycles increases in both scenarios. For this specific study we've conclude that automatic testing becomes worthwhile after the 36th execution cycle when compared with the same number of manual executions cycles, as shown in the following graphic: 

<br><img src="http://enear.github.io./public/qa-article-images/exec_by_cost_graphic.png"><br>


If we were to consider three daily test campaigns cycles, software automation testing would start to compensate after twelve days. 

## How to assess what should be automated 

As previously stated, today’s market contains increasingly complex applications that are constantly improving to offer more features to the end consumer. Between other factors when combined with agile development methodologies it is then possible that these continually mutating products achieve lower *time to market* business metrics, however, both existing and new features need always to be tested to ensure that they meet the expected product quality standards.
Test automation is then a powerful software development ally since it promotes and maintains quality patterns throughout the product´s lifecycle culminating in swifter results in the development cycles without sacrificing the team with quality-related overheads<sup>[2]</sup>.

Elegible product features that are candidates for test automation are usually those that were previously developed, the one that are considered stable or that have been already manually tested and with known results. On the other hand, unstable, temporary, incomplete features, or those whose automation is so complex, expensive, time-consuming and with high maintenance times are usually left out. This is due to the high initial costs of test automation which are only compensated and supported by successive regression test cycles being a medium for long product life cycles<sup>[3]</sup>.

## Functional automation tools 
One of the first questions that test automation raises refers to which languages, frameworks, libraries and tools can be used.
To answer this, let´s describe some of them:

+ **RobotFramework** An open source test automation framework developed in Python, based on high-level keywords, which even users with rudimentary programming skills can use. Although this framework has been developed with acceptance tests in mind, the same is able a range of layers taht can go from testing Web GUIs, Databases, APIs and others, depending on which library is included in the framework. It is also possible to create custom keywords and libraries using your own framework or language like Java or Python. Another significant advantage is the quality of produced reports. Besides RobotFramework’s Builtin library, there are other relevant external libraries. The most commonly used are: 
	
	* RequestLibrary – Contains keywords to test Web APIs. Allows you to execute and evaluate HTTP requests, and to analyse messages exchanged with this protocol. 
	* Selenium2Library – Interaction and evaluation of elements within an HTML page through interaction with DOM. Used essentially to test Web GUIs. 
	* XMLLibrary – Allows for navigation, removal, editing and creation of elements within an XML structure. 
	* JSONLibrary – Interaction with a JSON structure. 
	* DatabaseLibrary – Interaction with databases.

+ **Python, Java and C#** - These are more complex programming languages that require more technical knowledge in test automation. They are also more powerful and flexible, allowing greater interaction with the machine, to produce lower level tests. 

## Continuous Testing
With *time to market* metrics getting increasingly audacious, one must adopt strategies that allow products to develop without compromises to their quality. Continuous Deployment (CD) is a short-cycle software production and deployment strategy that results in a shorter time to market<sup>[4]</sup>. It is only possible through Continuous Integration (CI), which translates in small, frequent<sup>[5]</sup> integration of new code within the existing one. 

Since CD is as slow as its slowest phase, considering the vast number of code increments in the course of one day, how can we ensure product quality? Continuous Testing (CT) bridges the gap between CD and CI, by executing automated tests as part of a deployment and delivery pipeline<sup>[6][7][8]</sup>. This way, feedback can be swiftly obtained regarding business practices and, consequently<sup>[8]</sup> the integration and deployment risks of a given code increment.  
CT principles include maximum possible automation with early, frequent and swift testing. By including CT in the CI mechanism, automated test execution can be triggered through a CI tool whenever new code is added. Manual regression tests can thus be avoided, as they usually presume far superior execution times<sup>[7]</sup> which can compromise the product’s time to market. There are various CI tools in the market, though Jenkins, Travis, TeamCity and CircleCI are the most commonly used. Generally speaking, these tools support integration with requirement tools and defect management tools such as JIRA, HP Quality Center and TeamForge.

## Bibliography and Bibliographical References

[1] Hayes, Linda G., The Automated Testing Handbook, Software Testing Institute, 2nd Ed., March 1, 2004, ISBN - 978-0970746504

[2] Gryka, Maciej, When Is a Test Case Ready for Test Automation?, https://dzone.com , 19 August, 2017

[3] Basu, Soumyajit., Introduction to App Automation for Better Productivity and Scaling, https://dzone.com, 01 September, 2017

[4] Caum, Carl. “Continuous Delivery Vs. Continuous Deployment: What's the Diff?” Puppet, 30 Aug. 2013, puppet.com/blog/continuous-delivery-vs-continuous-deployment-what-s-diff.

[5] Earnshaw, Aliza. “Continuous Integration (CI) Success Depends on Automation.” Puppet, 13 June 2013, puppet.com/blog/continuous-integration-success-depends-on-automation.

[6] Pryce, Tom. “Continuous Testing for Continuous Delivery: What Does it Mean in Practice?” Feb. 2017, www.ca.com/content/dam/ca/us/files/white-paper/continuous-testing-for-continuous-delivery.pdf

[7] Kumar, Pavan. “Continuous Testing Opens The Gateway To “Faster Time To Market”.” EuroSTAR Software Testing, 24 July 2017, huddle.eurostarsoftwaretesting.com/continuous-testing-opens-gateway-faster-time-market/.

[8] Tricentis. “Continuous Testing vs. Test Automation What QA Needs to Know.” http://www.tricentis.com/wp-content/uploads/2017/03/Continuous_Testing_vs_Test_Automation.pdf.

## Appendix I
**Table 1** - Average test scripting/specification and execution times

||Automated Tests|Manual Tests|
|-|---------------|------------|
||**Average (min)**|**Average (min)**|
|Scripting/Manual Specification|290|35|
|Execution|1.25|4.5|

**Table 2** - Total test times versus number of executions for Automated Tests

|Time (min)/No of Executions|0|1|10|20|30|40|50|60|
|-|-|-|-|-|-|-|-|-|
|Insfrastructure Setup|180|0|0|0|0|0|0|0|
|Scripting|290|0|0|0|0|0|0|0|
|Execution<sup>(*)</sup>|0|1.25|12.5|25|37.5|50|62.5|75|
|Total Time (min)|470|1.25|12.5|25|37.5|50|62.5|75|

<sup>(*)</sup> When considering that no human interaction exists during these execution cycles, due to these being normally associated with a CI pipeline already implemented.

**Table 3** - Total test times versus number of executions for Manual Tests

|Time (min)/No of Executions|0|1|10|20|30|40|50|60|
|-|-|-|-|-|-|-|-|-|
|Insfrastructure Setup|60|0|0|0|0|0|0|0|
|Scripting|35|0|0|0|0|0|0|0|
|Execution<sup>(*)</sup>|0|4.5|45|90|135|180|225|270|
|Total Time (min)|95|4.5|45|90|135|180|225|270|

**Table 4** - Cost/min per Human Resource with a 1500€ gross salary 

|Cost/min per Human Resource|0.14€|
|-|---------------|

**Table 5** - Human costs when creating and executing test campaigns

|No of Executions|0|1|10|20|30|40|50|60|
|--|--|--|--|--|--|--|--|--|
|Total Cost for Manual Testing (€)|13.30|13.93|20.23|32.83|51.73|76.93|108.43|146.23|
|Total Cost for Automation Testing(€)|65.80|65.80|65.80|65.80|65.80|65.80|65.80|65.80|