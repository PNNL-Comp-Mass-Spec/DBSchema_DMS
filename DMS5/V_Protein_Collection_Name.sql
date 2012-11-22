/****** Object:  View [dbo].[V_Protein_Collection_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Protein_Collection_Name]
AS
SELECT LookupQ.Name,
       LookupQ.Type,
       CASE WHEN ISNULL(Org.OG_organismDBName, '') = LookupQ.Name 
            THEN CASE WHEN ISNULL(LookupQ.Description, '') = '' THEN 'PREFERRED' ELSE 'PREFERRED: ' + LookupQ.Description END
            ELSE LookupQ.Description 
            END AS Description,
       CASE WHEN LookupQ.Type IN ('Internal_standard', 'contaminant') 
            THEN NULL 
            Else PCU.Job_Usage_Count_Last12Months 
            END AS [Usage Last 12 Months],
        CASE WHEN LookupQ.Type IN ('Internal_standard', 'contaminant') 
            THEN NULL 
            Else PCU.Job_Usage_Count 
            END AS [Usage All Years],
       CASE WHEN LookupQ.Type IN ('Internal_standard', 'contaminant') 
            THEN NULL 
            Else SUBSTRING(CONVERT(varchar(32), dbo.GetDateWithoutTime(PCU.Most_Recently_Used), 120), 1, 10) 
            END AS [Most Recent Usage],
       LookupQ.Entries,
       LookupQ.[Organism Name],
       LookupQ.ID
FROM ( SELECT Name,
              Type,
              Description,
              Entries,
              CASE
                  WHEN Type = 'Internal_Standard' OR
                       Type = 'contaminant' THEN ''
                  ELSE Organism_Name
              END AS [Organism Name],
              ID,
              CASE
                  WHEN Type = 'internal_standard' THEN 1
                  WHEN Type = 'contaminant' THEN 2
                  ELSE 0
              END AS TypeSortOrder
       FROM S_V_Protein_Collection_Picker CP ) LookupQ
       LEFT JOIN dbo.T_Organisms Org ON LookupQ.[Organism Name] = Org.OG_Name
       LEFT OUTER JOIN T_Protein_Collection_Usage PCU ON LookupQ.ID = PCU.Protein_Collection_ID
GROUP BY LookupQ.Name, LookupQ.Type, LookupQ.Description, LookupQ.Entries, LookupQ.[Organism Name], 
         LookupQ.ID, LookupQ.TypeSortOrder, PCU.Most_Recently_Used, PCU.Job_Usage_Count, PCU.Job_Usage_Count_Last12Months, Org.OG_organismDBName
 


GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_Name] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_Name] TO [PNL\D3M580] AS [dbo]
GO
