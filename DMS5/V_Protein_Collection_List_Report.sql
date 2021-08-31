/****** Object:  View [dbo].[V_Protein_Collection_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collection_List_Report]
AS
SELECT LookupQ.ID,
       LookupQ.[Name],
       CASE
           WHEN ISNULL(Org.OG_organismDBName, '') = LookupQ.[Name] THEN 
             CASE
                 WHEN ISNULL(LookupQ.[Description], '') = '' THEN 'PREFERRED'
                 ELSE 'PREFERRED: ' + LookupQ.[Description]
             END
           ELSE LookupQ.[Description]
       END AS [Description],
       LookupQ.[Organism Name],
       LookupQ.[State],
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
              END AS [Organism Name],
              [State]
       FROM ( SELECT [Filename] As [Name],
                     [Type],
                     [Description],
                     [Source],
                     NumProteins As Entries,
                     NumResidues As Residues,
              CASE
                  WHEN [Type] IN ('Internal_Standard', 'contaminant', 'old_contaminant') THEN 1 ELSE 0 END AS IntStandardOrContaminant,
                     Organism_Name,
                     Protein_Collection_ID As ID,
                     State_Name As [State]
              FROM S_V_Protein_Collections_by_Organism 
            ) AS CP 
     ) AS LookupQ
     LEFT JOIN dbo.T_Organisms Org
       ON LookupQ.[Organism Name] = Org.OG_Name
     LEFT OUTER JOIN T_Protein_Collection_Usage PCU
       ON LookupQ.ID = PCU.Protein_Collection_ID
GROUP BY LookupQ.ID, LookupQ.[Name], LookupQ.[Description], LookupQ.[Organism Name], 
         LookupQ.[State], LookupQ.Entries, LookupQ.Residues,
         PCU.Job_Usage_Count_Last12Months, PCU.Job_Usage_Count,
         PCU.Most_Recently_Used, LookupQ.[Type], LookupQ.[Source], 
         LookupQ.IntStandardOrContaminant, Org.OG_organismDBName


GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_List_Report] TO [DDL_Viewer] AS [dbo]
GO
