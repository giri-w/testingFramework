<?xml version="1.0" encoding="utf-16"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl">
  
  <xsl:output method="html" encoding="utf-16" indent="yes" />

  
  <!-- .................................................
       ..  Root
       ................................................. -->
  
  <xsl:template match="/">
    <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
    <html lang="en">
      <head>
        <title>Device Test Record of <xsl:value-of select="TestReport/@serialNr"/> / <xsl:value-of select="TestReport/@subNr"/></title>
        <link rel="stylesheet" type="text/css">
          <xsl:attribute name="href"><xsl:value-of select="TestReport/@resources"/>\Report.css</xsl:attribute>
        </link>
      </head>
      <body>
        <header>
          <meta charset="utf-16"/>
          <div id="header">
            <img id="logo">
              <xsl:attribute name="src"><xsl:value-of select="TestReport/@resources"/>\Logo.png</xsl:attribute>
            </img>
            <div id="address">
              DEMCON<br/>
              Institutenweg 25<br/>
              7521 PH Enschede<br/>
              Tel.: +31 (0)88 115 20 00<br/>
              E-mail: <a href="mailto:info@demcon.nl">info@demcon.nl</a><br/><br/>
              KvK-nr.: 060 703 25<br/>
              btw-nr.: 8018.33.723 B 01
            </div>
          </div>
          
          <h1>Device Test Record</h1>
          
          <table class="summary">
            <caption>Configuration</caption>
            <tr>
              <th>Serial number</th>
              <td>
                <xsl:value-of select="TestReport/@serialNr"/>
              </td>
            </tr>
            <tr>
              <th>WO/complaint</th>
              <td>
                <xsl:value-of select="TestReport/@subNr"/>
              </td>
            </tr>
            <xsl:for-each select="//TestReportSection">
              <xsl:if test="string-length(TestSequence/@AddtionalInformationRequestText1) > 0 and string-length(TestSequence/@AddtionalInformation1) > 0">
                <tr>
                  <th>
                    <xsl:value-of select="TestSequence/@AddtionalInformationRequestText1"/>
                  </th>
                  <td>
                    <xsl:value-of select="TestSequence/@AddtionalInformation1"/>
                  </td>
                </tr>
              </xsl:if>
              <xsl:if test="string-length(TestSequence/@AddtionalInformationRequestText2) > 0 and string-length(TestSequence/@AddtionalInformation2) > 0">
                <tr>
                  <th>
                    <xsl:value-of select="TestSequence/@AddtionalInformationRequestText2"/>
                  </th>
                  <td>
                    <xsl:value-of select="TestSequence/@AddtionalInformation2"/>
                  </td>
                </tr>
              </xsl:if>
              <xsl:if test="string-length(TestSequence/@HardwareID) > 0 and string-length(TestSequence/@HardwareIDType) > 0">
                <tr>
                  <th>
                    <xsl:value-of select="TestSequence/@HardwareIDType"/>
                  </th>
                  <td>
                    <xsl:value-of select="TestSequence/@HardwareID"/>
                  </td>
                </tr>
              </xsl:if>
            </xsl:for-each>
            <tr>
              <th>
                Version
              </th>
              <td>
                <xsl:variable name="version"><xsl:value-of select="//TestSequence[string-length(@NanoCoreVersion) > 0 and @Conclusion != 'NotTested']/@NanoCoreVersion"/></xsl:variable>
                <xsl:choose>
                  <xsl:when test="//TestSequence[string-length(@NanoCoreVersion) > 0 and @Conclusion != 'NotTested' and string(@NanoCoreVersion) != $version]">(multiple)</xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="format-version">
                      <xsl:with-param name="version" select="$version"/>
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
          </table>
            
          <table class="summary">
            <caption>Overview test conclusions</caption>
            <tr>
              <th>Report timestamp</th>
              <td>
                <xsl:value-of select="TestReport/@timestamp"/>
              </td>
            </tr>
            <tr>
              <th>Test result path</th>
              <td>
                <a>
                  <xsl:attribute name="href">
                    file://<xsl:value-of select="TestReport/@path"/>
                  </xsl:attribute>
                  <xsl:value-of select="TestReport/@path"/>
                </a>
              </td>
            </tr>
            <xsl:for-each select="//TestReportSection">
              <tr class="conclusion">
                <xsl:apply-templates select="TestSequence/@Conclusion" mode="conclusion-attr"/>
                <th>
                  <xsl:value-of select="TestSequence/@Name"/>
                </th>
                <td>
                  <a>
                    <xsl:attribute name="href">#seq<xsl:value-of select="position()"/></xsl:attribute>
                    <xsl:apply-templates select="TestSequence/@Conclusion" mode="conclusion"/>
                  </a>
                </td>
              </tr>
            </xsl:for-each>
          </table>
        </header>
        
        <xsl:apply-templates select="*"/>

        <section class="appendix" id="xml">
          <h2>Report input</h2>
          <code>
            <xsl:apply-templates mode="escape"/>
          </code>
        </section>
      </body>
    </html>
  </xsl:template>

  
  
  <!-- .................................................
       ..  Test report parsing
       ................................................. -->
  
  <xsl:template match="TestReportSection">
    <section class="testsequence">
      <h2>
        <xsl:attribute name="id">seq<xsl:value-of select="position()"/></xsl:attribute>
        Test sequence: <xsl:value-of select="TestSequence/@Name"/>
      </h2>
      <table class="summary">
        <tr>
          <th>File</th>
          <td>
            <a>
              <xsl:attribute name="href">file://<xsl:value-of select="@path"/></xsl:attribute>
              <xsl:call-template name="substring-after-last">
                <xsl:with-param name="value" select="@path"/>
                <xsl:with-param name="pattern" select="'\'"/>
              </xsl:call-template>
            </a>
          </td>
        </tr>
        <tr>
          <th>Serial number</th>
          <td>
            <xsl:if test="string(TestSequence/@SerialNumber) != string(//TestReport/@serialNr)">
              <xsl:attribute name="class">error</xsl:attribute>
            </xsl:if>
            <xsl:value-of select="TestSequence/@SerialNumber"/>
          </td>
        </tr>
        <tr>
          <th>WO/complaint</th>
          <td>
            <xsl:if test="string(TestSequence/@Dwo) != string(//TestReport/@subNr)">
              <xsl:attribute name="class">error</xsl:attribute>
            </xsl:if>
            <xsl:value-of select="TestSequence/@Dwo"/>
          </td>
        </tr>
        <tr>
          <th>Operator</th>
          <td>
            <xsl:value-of select="TestSequence/@OperatorID"/>
          </td>
        </tr>
        <tr>
          <th>PC</th>
          <td>
            <xsl:value-of select="TestSequence/@PCID"/>
          </td>
        </tr>
        <xsl:if test="string-length(TestSequence/@AddtionalInformationRequestText1) > 0 and string-length(TestSequence/@AddtionalInformation1) > 0">
          <tr>
            <th>
              <xsl:value-of select="TestSequence/@AddtionalInformationRequestText1"/>
            </th>
            <td>
              <xsl:value-of select="TestSequence/@AddtionalInformation1"/>
            </td>
          </tr>
        </xsl:if>
        <xsl:if test="string-length(TestSequence/@AddtionalInformationRequestText2) > 0 and string-length(TestSequence/@AddtionalInformation2) > 0">
          <tr>
            <th>
              <xsl:value-of select="TestSequence/@AddtionalInformationRequestText2"/>
            </th>
            <td>
              <xsl:value-of select="TestSequence/@AddtionalInformation2"/>
            </td>
          </tr>
        </xsl:if>
        <xsl:if test="string-length(TestSequence/@HardwareID) > 0 and string-length(TestSequence/@HardwareIDType) > 0">
          <tr>
            <th>
              <xsl:value-of select="TestSequence/@HardwareIDType"/>
            </th>
            <td>
              <xsl:value-of select="TestSequence/@HardwareID"/>
            </td>
          </tr>
        </xsl:if>
        <tr>
          <th>
            Version
          </th>
          <td>
            <xsl:call-template name="format-version">
              <xsl:with-param name="version" select="TestSequence/@NanoCoreVersion"/>
            </xsl:call-template>
          </td>
        </tr>
        <tr class="conclusion">
          <xsl:apply-templates select="TestSequence/@Conclusion" mode="conclusion-attr"/>
          <th>Conclusion</th>
          <td>
            <xsl:apply-templates select="TestSequence/@Conclusion" mode="conclusion"/>
          </td>
        </tr>
      </table>

      <xsl:apply-templates select="*" />
    </section>
  </xsl:template>

  <xsl:template name="string-replace-all">
    <xsl:param name="text"/>
    <xsl:param name="replace"/>
    <xsl:param name="by"/>
    <xsl:param name="disable-output-escaping" select="no"/>
    <xsl:choose>
      <xsl:when test="contains($text,$replace)">
        <xsl:if test="$disable-output-escaping = 'yes'">
          <xsl:value-of select="substring-before($text,$replace)" disable-output-escaping="yes"/>
          <xsl:value-of select="$by" disable-output-escaping="yes"/>
        </xsl:if>
        <xsl:if test="$disable-output-escaping != 'yes'">
          <xsl:value-of select="substring-before($text,$replace)"/>
          <xsl:value-of select="$by"/>
        </xsl:if>
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="substring-after($text,$replace)"/>
          <xsl:with-param name="replace" select="$replace"/>
          <xsl:with-param name="by" select="$by"/>
          <xsl:with-param name="disable-output-escaping" select="$disable-output-escaping"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$disable-output-escaping = 'yes'">
          <xsl:value-of select="$text" disable-output-escaping="yes"/>
        </xsl:if>
        <xsl:if test="$disable-output-escaping != 'yes'">
          <xsl:value-of select="$text" disable-output-escaping="no"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="substring-after-last">
    <xsl:param name="value" />
    <xsl:param name="pattern" />
    <xsl:variable name="result">
      <xsl:value-of select="substring-after($value, $pattern)"/>
    </xsl:variable>
    <xsl:if test="string-length($result) > 0">
      <xsl:call-template name="substring-after-last">
        <xsl:with-param name="value" select="$result"/>
        <xsl:with-param name="pattern" select="$pattern"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="string-length($result) = 0">
      <xsl:value-of select="$value"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@NanoCoreVersion" name="format-version">
    <xsl:param name="version" select="string(.)"/>
    <dl class="version">
      <dt>
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text">
            <xsl:call-template name="string-replace-all">
              <xsl:with-param name="text" select="$version"/>
              <xsl:with-param name="replace">;</xsl:with-param>
              <xsl:with-param name="by">&lt;/dd&gt;&lt;dt&gt;</xsl:with-param>
              <xsl:with-param name="disable-output-escaping">yes</xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
          <xsl:with-param name="replace">: </xsl:with-param>
          <xsl:with-param name="by">&lt;/dt&gt;&lt;dd&gt;</xsl:with-param>
          <xsl:with-param name="disable-output-escaping">yes</xsl:with-param>
        </xsl:call-template>
      </dt>
    </dl>
  </xsl:template>

  <xsl:template match="@* | node()" mode="conclusion">
    <span>
      <xsl:call-template name="conclusion-attr" />
      <xsl:value-of select="."/>
    </span>
  </xsl:template>

  <xsl:template match="@* | node()" mode="conclusion-attr" name="conclusion-attr">
    <xsl:choose>
      <xsl:when test="string(.) = 'NotTested'">
        <xsl:attribute name="class">conclusion conclusion_nottested</xsl:attribute>
      </xsl:when>
      <xsl:when test="string(.) = 'Failed'">
        <xsl:attribute name="class">conclusion conclusion_failed</xsl:attribute>
      </xsl:when>
      <xsl:when test="string(.) = 'Passed'">
        <xsl:attribute name="class">conclusion conclusion_passed</xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="class">conclusion conclusion_unknown</xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@* | node()" mode="conclusion-cell">
    <xsl:apply-templates select="@Conclusion" mode="conclusion-attr"/>
    <xsl:apply-templates select="@Conclusion" mode="conclusion"/>
  </xsl:template>

  <xsl:template match="Test">
    <table class="results">
      <tr class="test">
        <td class="description">
          <em><xsl:value-of select="@Name"/></em>
          <xsl:for-each select="@*[local-name() != 'Conclusion' and local-name() != 'Name' and local-name() != 'type' and string(current()) != '']">
            <br/><xsl:value-of select="."/>
          </xsl:for-each>
        </td>
        <td class="measurement"/>
        <td class="conclusion">
          <xsl:apply-templates select="." mode="conclusion-cell" />
        </td>
      </tr>
      <xsl:apply-templates select="*"/>
    </table>
  </xsl:template>

  <xsl:template match="TestStep">
    <tr class="teststep">
      <td class="description">
        <xsl:for-each select="@*[local-name() != 'Conclusion' and local-name() != 'type' and string(current()) != '']">
          <xsl:value-of select="."/><br/>
        </xsl:for-each>
      </td>
      <td class="measurement"/>
      <td class="conclusion">
        <xsl:apply-templates select="." mode="conclusion-cell" />
      </td>
    </tr>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="Result">
    <xsl:variable name="unit">
      <xsl:if test="string-length(@Units) > 0">
        <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
        <xsl:value-of select="@Units"/>
      </xsl:if>
    </xsl:variable>
    <tr class="result">
      <td class="description">
        <xsl:value-of select="@Name"/>
        <xsl:if test="string-length(@MinValue) > 0 or string-length(@MaxValue) > 0">
          (limit:
          <span class="value"><xsl:value-of select="@MinValue"/></span>
          <xsl:text disable-output-escaping="yes"> &amp;ndash; </xsl:text>
          <span class="value"><xsl:value-of select="@MaxValue"/><xsl:value-of disable-output-escaping="yes" select="$unit"/></span>)
        </xsl:if>
        <xsl:if test="string-length(@Remarks) > 0">
          <br/>
          <xsl:value-of select="@Remarks"/>
        </xsl:if>
      </td>
      <td class="measurement">
        <xsl:value-of select="@ResultValue"/>
        <span class="value"><xsl:value-of select="@MeasuredValue"/><xsl:value-of disable-output-escaping="yes" select="$unit"/></span>
      </td>
      <td class="conclusion">
        <xsl:apply-templates select="." mode="conclusion-cell" />
      </td>
    </tr>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:apply-templates select="*"/>
  </xsl:template>

    <!-- .................................................
       ..  Debugging output
       ................................................. -->
  
  <xsl:template match="*" mode="escape">
    <!-- Begin opening tag -->
    <div class="tag">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>

    <!-- Namespaces - ->
    <xsl:for-each select="namespace::*">
      <xsl:text> xmlns</xsl:text>
      <xsl:if test="name() != ''">
        <xsl:text>:</xsl:text>
        <xsl:value-of select="name()"/>
      </xsl:if>
      <xsl:text>='</xsl:text>
      <xsl:call-template name="escape-xml">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
      <xsl:text>'</xsl:text>
    </xsl:for-each>-->

    <!-- Attributes -->
    <xsl:for-each select="@*">
      <xsl:text> </xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:text>='</xsl:text>
      <xsl:call-template name="escape-xml">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
      <xsl:text>'</xsl:text>
    </xsl:for-each>

    <!-- End opening tag -->
    <xsl:text>&gt;</xsl:text>
    <br/>
    <xsl:if test="node()">
      <div class="tag-body">
        <!-- Content (child elements, text nodes, and PIs) -->
        <xsl:apply-templates select="node()" mode="escape" />
      </div>
    </xsl:if>

    <!-- Closing tag -->
    <xsl:text>&lt;/</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&gt;</xsl:text>
    </div>
  </xsl:template>

  <xsl:template match="text()" mode="escape">
    <xsl:call-template name="escape-xml">
      <xsl:with-param name="text" select="."/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="processing-instruction()" mode="escape">
    <xsl:text>&lt;?</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text> </xsl:text>
    <xsl:call-template name="escape-xml">
      <xsl:with-param name="text" select="."/>
    </xsl:call-template>
    <xsl:text>?&gt;</xsl:text>
  </xsl:template>

  <xsl:template name="escape-xml">
    <xsl:param name="text"/>
    <xsl:if test="$text != ''">
      <xsl:variable name="head" select="substring($text, 1, 1)"/>
      <xsl:variable name="tail" select="substring($text, 2)"/>
      <xsl:choose>
        <xsl:when test="$head = '&amp;'">&amp;amp;</xsl:when>
        <xsl:when test="$head = '&lt;'">&amp;lt;</xsl:when>
        <xsl:when test="$head = '&gt;'">&amp;gt;</xsl:when>
        <xsl:when test="$head = '&quot;'">&amp;quot;</xsl:when>
        <xsl:when test="$head = &quot;&apos;&quot;">&amp;apos;</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$head"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="escape-xml">
        <xsl:with-param name="text" select="$tail"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
