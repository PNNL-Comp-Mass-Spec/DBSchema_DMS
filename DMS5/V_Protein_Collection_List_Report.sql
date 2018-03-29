/****** Object:  View [dbo].[V_Protein_Collection_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Protein_Collection_List_Report]
AS
-- This view uses V_Collection_Picker in the Protein_Sequences database
-- That view excludes inactive protein collections (by filtering to show collections with state 1, 2, or 3)
SELECT LookupQ.ID,
       LookupQ.[Name],
       CASE
           WHEN ISNULL(Org.OG_organismDBName, '') = LookupQ.[Name] THEN 
             CASE
                 WHEN ISNULL(LookupQ.[Description], '') = '' THEN 'PREFERRED'
                 ELSE 'PREFERRED: ' + LookupQ.[Description]
             END
           ELSE LookupQ.[Description]
       END AS Description,
       LookupQ.[Organism Name],
       LookupQ.Entries,
       LookupQ.Residues,
       CASE
           WHEN IntStandardOrContaminant > 0 THEN NULL
           ELSE PCU.Job_Usage_Count_Last12Months
       END AS [Usage Last 12 Months],
       CASE
           WHEN IntStandardOrContaminant > 0 THEN NULL
           ELSE PCU.Job_Usage_Count
       END AS [Usage All Years],
       CASE
           WHEN IntStandardOrContaminant > 0 THEN NULL
           ELSE SUBSTRING(CONVERT(varchar(32), dbo.GetDateWithoutTime(PCU.Most_Recently_Used), 120), 1, 10)
       END AS [Most Recent Usage],
       LookupQ.[Type],
       LookupQ.[Source]
FROM ( SELECT [Name],
              [Type],
              [Description],
              [Source],
              Entries,
              Residues,
              IntStandardOrContaminant,
              ID,
              CASE
                  WHEN IntStandardOrContaminant > 0 THEN ''
                  ELSE Organism_Name
              END AS [Organism Name]
       FROM ( SELECT [Name],
                     [Type],
                     [Description],
                     [Source],
                     Entries,
                     Residues,
              CASE
                  WHEN [Type] IN ('Internal_Standard', 'contaminant', 'old_contaminant') THEN 1 ELSE 0 END AS IntStandardOrContaminant,
                     Organism_Name,
                     ID
              FROM S_V_Protein_Collection_Picker 
            ) AS CP 
     ) AS LookupQ
     LEFT JOIN dbo.T_Organisms Org
       ON LookupQ.[Organism Name] = Org.OG_Name
     LEFT OUTER JOIN T_Protein_Collection_Usage PCU
       ON LookupQ.ID = PCU.Protein_Collection_ID
GROUP BY LookupQ.[Name], LookupQ.[Type], LookupQ.[Description], LookupQ.[Source], LookupQ.Entries, LookupQ.Residues,
         LookupQ.[Organism Name], LookupQ.ID, LookupQ.IntStandardOrContaminant, PCU.Most_Recently_Used,
         PCU.Job_Usage_Count, PCU.Job_Usage_Count_Last12Months, Org.OG_organismDBName


GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_List_Report] TO [DDL_Viewer] AS [dbo]
GO
