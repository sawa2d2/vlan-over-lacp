<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>

  <!-- Identity transform to copy everything as is -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <!-- Enable Open vSwitch support and assign a static name to each device -->
  <xsl:template match="/domain/devices/interface[@type='bridge']">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
      <virtualport type="openvswitch"/>
      <target>
        <xsl:attribute name="dev">
          <xsl:value-of select="concat('${tap_prefix}p', count(preceding::interface[@type='bridge']) + 1)"/>
        </xsl:attribute>
      </target>

    </xsl:copy>
  </xsl:template>

  <!-- Use SATA CD-ROM for Linux setup -->
  <xsl:template match="target[@bus='ide']">
    <xsl:copy>
      <xsl:apply-templates select="@*[name()!='bus']"/>
      <xsl:attribute name="bus">sata</xsl:attribute>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
