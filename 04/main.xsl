<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:nikon="nikon"
  exclude-result-prefixes="xs nikon"
>

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:template match="/">
    <xsl:call-template name="handle-moves">
      <xsl:with-param name="moves" select="bingo/moves/move"/>
      <xsl:with-param name="boards" select="bingo/boards/board"/>
    </xsl:call-template>
    <xsl:call-template name="handle-moves">
      <xsl:with-param name="moves" select="bingo/moves/move"/>
      <xsl:with-param name="boards" select="bingo/boards/board"/>
      <xsl:with-param name="try-to-lose" select="true()"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="handle-moves">
    <xsl:param name="moves"/>
    <xsl:param name="boards"/>
    <xsl:param name="try-to-lose" as="xs:boolean" select="false()"/>
    <xsl:variable name="marked-boards" as="node()">
      <wrapper>
        <xsl:for-each select="$boards">
          <xsl:call-template name="mark-board">
            <xsl:with-param name="move" select="$moves[1]"/>
            <xsl:with-param name="board" select="."/>
          </xsl:call-template>
        </xsl:for-each>
      </wrapper>
    </xsl:variable>
    <xsl:variable name="cleaned-boards" as="node()*" select="
      if ($try-to-lose) then
        for $b in $marked-boards/board return
        if (nikon:isWinningBoard($b)) then () else $b
      else
        $marked-boards/board
    "/>
    <xsl:variable name="winning-board" as="node()*" select="nikon:getWinningBoard(
        if (count($cleaned-boards)) then $cleaned-boards else $marked-boards/board
    )"/>
    <xsl:choose>
      <xsl:when test="not(count($moves)) or count($winning-board)">
        <xsl:value-of select="
          concat('2021-12-04 Part ', if ($try-to-lose) then '2' else '1', ': ',
          nikon:sumUnmarkedFields($winning-board, 0) * number($moves[1]))"
        />
        <xsl:text>&#xa;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="handle-moves">
          <xsl:with-param name="moves" select="$moves[position() > 1]"/>
          <xsl:with-param name="boards" select="$cleaned-boards"/>
          <xsl:with-param name="try-to-lose" select="$try-to-lose"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="mark-board">
    <xsl:param name="move"/>
    <xsl:param name="board"/>
    <board>
      <xsl:for-each select="$board/field">
        <xsl:call-template name="mark-field">
          <xsl:with-param name="move" select="$move"/>
          <xsl:with-param name="field" select="."/>
        </xsl:call-template>
      </xsl:for-each>
    </board>
  </xsl:template>

  <xsl:template name="mark-field">
    <xsl:param name="move"/>
    <xsl:param name="field"/>
    <xsl:choose>
      <xsl:when test="text()[. = $move]">
        <field marked="marked"><xsl:value-of select="$move"/></field>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$field"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="nikon:getWinningBoard" as="node()*">
    <xsl:param name="boards"/>
    <xsl:sequence select="
      if (not(count($boards))) then () else
      if (nikon:isWinningBoard($boards[1])) then $boards[1]/field else
      nikon:getWinningBoard($boards[position() > 1])
    "/>
  </xsl:function>

  <xsl:function name="nikon:isWinningBoard" as="xs:boolean">
    <xsl:param name="board"/>
    <xsl:sequence select="
      (some $x in (1, 6, 11, 16, 21) satisfies
        $board/field[$x + 0]/@marked and 
        $board/field[$x + 1]/@marked and
        $board/field[$x + 2]/@marked and
        $board/field[$x + 3]/@marked and
        $board/field[$x + 4]/@marked
      ) or (some $y in (1, 2, 3, 4, 5) satisfies
        $board/field[$y + 0]/@marked and
        $board/field[$y + 5]/@marked and
        $board/field[$y + 10]/@marked and
        $board/field[$y + 15]/@marked and
        $board/field[$y + 20]/@marked
      )
    "/>
  </xsl:function>

  <xsl:function name="nikon:sumUnmarkedFields" as="xs:double">
    <xsl:param name="board" as="node()*"/>
    <xsl:param name="acc" as="xs:double"/>
    <xsl:sequence select="
      if (not(count($board))) then $acc else
      nikon:sumUnmarkedFields(
        $board[position() > 1],
        if ($board[1]/@marked) then $acc else $acc + number($board[1])
      )
    "/>
  </xsl:function>

</xsl:stylesheet>