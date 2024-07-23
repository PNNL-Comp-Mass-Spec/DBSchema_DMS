/****** Object:  View [dbo].[V_Protein_Collection_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Protein_Collection_Name]
AS
SELECT LookupQ.name,
       LookupQ.state,
       CASE WHEN ISNULL(Org.OG_organismDBName, '') = LookupQ.name
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
            Else SUBSTRING(CONVERT(varchar(32), dbo.get_date_without_time(PCU.Most_Recently_Used), 120), 1, 10)
            END AS most_recent_usage,
       LookupQ.entries,
       LookupQ.organism_name,
       LookupQ.type,
       LookupQ.sort_weight,
       LookupQ.id
FROM ( SELECT PC.Name,
              PC.State_Name AS State,
              PC.Description,
              PC.Entries,
              CASE
                  WHEN PC.Type In ('Internal_Standard', 'contaminant', 'old_contaminant') THEN ''
                  ELSE Org.OG_name
              END AS Organism_Name,
              PC.ID,
              CASE WHEN PC.State_Name IN ('New', 'Provisional', 'Production') THEN
                  CASE WHEN PC.Type = 'internal_standard' THEN 3
                       WHEN PC.Type In ('contaminant', 'old_contaminant') THEN 2
                       ELSE 1
                  END
              ELSE
                  CASE WHEN PC.Type = 'internal_standard' THEN 6
                       WHEN PC.Type In ('contaminant', 'old_contaminant') THEN 5
                       ELSE 4
                 END
              END AS Sort_Weight,
              PC.Type
       FROM T_Cached_Protein_Collections PC INNER JOIN
	        T_Organisms Org ON PC.Organism_ID = Org.Organism_ID
       WHERE Not IsNull(PC.State_Name, '') IN ('Unknown', 'Retired', 'Proteins_Deleted')
       ) LookupQ
       LEFT JOIN dbo.T_Organisms Org ON LookupQ.Organism_Name = Org.OG_Name
       LEFT OUTER JOIN T_Protein_Collection_Usage PCU ON LookupQ.ID = PCU.Protein_Collection_ID
GROUP BY LookupQ.Name, LookupQ.State, Org.OG_organismDBName, LookupQ.description,
         PCU.Job_Usage_Count, PCU.Job_Usage_Count_Last12Months, PCU.Most_Recently_Used, LookupQ.Entries,
         LookupQ.Organism_Name, LookupQ.Type, LookupQ.Sort_Weight, LookupQ.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_Name] TO [DDL_Viewer] AS [dbo]
GO
