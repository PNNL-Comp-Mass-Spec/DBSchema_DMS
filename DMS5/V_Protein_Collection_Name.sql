/****** Object:  View [dbo].[V_Protein_Collection_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collection_Name]
AS
SELECT LookupQ.name,
       LookupQ.type,
       CASE WHEN ISNULL(Org.og_organismdbname, '') = LookupQ.name
            THEN CASE WHEN ISNULL(LookupQ.description, '') = '' THEN 'PREFERRED' ELSE 'PREFERRED: ' + LookupQ.Description END
            ELSE LookupQ.description
            END AS description,
       CASE WHEN LookupQ.Type IN ('Internal_standard', 'contaminant', 'old_contaminant')
            THEN NULL
            Else PCU.job_usage_count_last12months
            END AS usage_last_12_months,
       CASE WHEN LookupQ.Type IN ('Internal_standard', 'contaminant', 'old_contaminant')
            THEN NULL
            Else PCU.job_usage_count
            END AS usage_all_years,
       CASE WHEN LookupQ.Type IN ('Internal_standard', 'contaminant', 'old_contaminant')
            THEN NULL
            Else SUBSTRING(CONVERT(varchar(32), dbo.GetDateWithoutTime(PCU.Most_Recently_Used), 120), 1, 10)
            END AS most_recent_usage,
       LookupQ.entries,
       LookupQ.organism_name,
       LookupQ.id
FROM ( SELECT PC.Name,
              PC.Type,
              PC.Description,
              PC.Entries,
              CASE
                  WHEN PC.Type In ('Internal_Standard', 'contaminant', 'old_contaminant') THEN ''
                  ELSE Org.OG_name
              END AS Organism_Name,
              PC.ID,
              Case
                  WHEN PC.Type = 'Internal_Standard' THEN 1
                  WHEN PC.Type In ('contaminant','old_contaminant') THEN 2
                  ELSE 0
              END AS TypeSortOrder
       FROM T_Cached_Protein_Collections PC INNER JOIN
	        T_Organisms Org ON PC.Organism_ID = Org.Organism_ID
       WHERE IsNull(PC.State_Name, '') <> 'Retired'
       ) LookupQ
       LEFT JOIN dbo.T_Organisms Org ON LookupQ.Organism_Name = Org.OG_Name
       LEFT OUTER JOIN T_Protein_Collection_Usage PCU ON LookupQ.ID = PCU.Protein_Collection_ID
GROUP BY LookupQ.Name, LookupQ.Type, LookupQ.Description, LookupQ.Entries, LookupQ.Organism_Name,
         LookupQ.ID, LookupQ.TypeSortOrder, PCU.Most_Recently_Used, PCU.Job_Usage_Count, PCU.Job_Usage_Count_Last12Months, Org.OG_organismDBName


GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_Name] TO [DDL_Viewer] AS [dbo]
GO
