/****** Object:  View [dbo].[V_Script_Dot_Format] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Script_Dot_Format
AS
SELECT     
	Script, 
	TS.Step_Number + ' [label="' + CONVERT(varchar(12), TS.Step_Number) + ' ' + 
	TS.Step_Tool + 
	CASE WHEN Special_Instructions IS NULL THEN '' ELSE ' (' + Special_Instructions + ')' END + '"' + '] ' + 
	CASE WHEN IsNull(Special_Instructions, '') = 'Clone' THEN '[shape=trapezium, ' ELSE '[shape=box, ' END + 
    'color=black' + '];' AS line, 
	0 AS seq
FROM
(
	SELECT
		Script, 
		xmlNode.value('@Number', 'nvarchar(128)') Step_Number, 
		xmlNode.value('@Tool', 'nvarchar(128)') Step_Tool,
		xmlNode.value('@Special', 'nvarchar(128)') Special_Instructions
	FROM
		T_Scripts CROSS APPLY Contents.nodes('//Step') AS R(xmlNode)
) TS INNER JOIN
	T_Step_Tools ON TS.Step_Tool = T_Step_Tools.Name
UNION
SELECT
	Script, 
	CONVERT(varchar(12), Target_Step_Number) + ' -> ' + CONVERT(varchar(12), Step_Number) + 
	CASE WHEN Condition_Test IS NULL THEN '' ELSE ' [label="Skip if:' + Condition_Test + '"]' END + 
	CASE WHEN Enable_Only > 0 THEN ' [style=dotted]' ELSE '' END + ';' AS line,
	1 AS seq
FROM
(
	SELECT
		Script, 
		xmlNode.value('../@Number', 'nvarchar(24)') Step_Number, 
		xmlNode.value('@Step_Number', 'nvarchar(24)') Target_Step_Number,
		xmlNode.value('@Test', 'nvarchar(128)') Condition_Test, 
		xmlNode.value('@Value', 'nvarchar(256)') Test_Value, isnull(xmlNode.value('@Enable_Only', 'nvarchar(24)'), 0) Enable_Only
	FROM
		T_Scripts CROSS APPLY Contents.nodes('//Depends_On') AS R(xmlNode)
) TD
GO
GRANT VIEW DEFINITION ON [dbo].[V_Script_Dot_Format] TO [DDL_Viewer] AS [dbo]
GO
