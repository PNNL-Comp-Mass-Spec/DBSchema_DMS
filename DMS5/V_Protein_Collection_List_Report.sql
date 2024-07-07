/****** Object:  View [dbo].[V_Protein_Collection_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Protein_Collection_List_Report]
AS
SELECT LookupQ.id,
       LookupQ.name,
       CASE
           WHEN ISNULL(Org.og_organismdbname, '') = LookupQ.Name THEN
             CASE
                 WHEN ISNULL(LookupQ.description, '') = '' THEN 'PREFERRED'
                 ELSE 'PREFERRED: ' + LookupQ.description
             END
           ELSE LookupQ.description
       END AS description,
       LookupQ.organism_name,
       LookupQ.state,
       LookupQ.entries,
       LookupQ.residues,
       CASE
           WHEN IntStandardOrContaminant > 0 THEN NULL
           ELSE PCU.job_usage_count_last12months
       END AS usage_last_12_months,
       CASE
           WHEN IntStandardOrContaminant > 0 THEN NULL
           ELSE PCU.job_usage_count
       END AS usage_all_years,
       CASE
           WHEN IntStandardOrContaminant > 0 THEN NULL
           ELSE SUBSTRING(CONVERT(varchar(32), dbo.get_date_without_time(PCU.Most_Recently_Used), 120), 1, 10)
       END AS most_recent_usage,
       LookupQ.Includes_Contaminants As includes_contaminants,
       LookupQ.FileSizeMB As file_size_mb,
       LookupQ.[type],
       LookupQ.source
FROM ( SELECT Name,
              [type],
              Description,
              Source,
              Entries,
              Residues,
              IntStandardOrContaminant,
              id,
              CASE
                  WHEN IntStandardOrContaminant > 0 THEN ''
                  ELSE Organism_Name
              END AS Organism_Name,
              State,
              Includes_Contaminants,
              FileSizeMB
       FROM ( SELECT Collection_Name As Name,
                     [type],
                     Description,
                     Source,
                     Num_Proteins As Entries,
                     Num_Residues As Residues,
                     CASE WHEN [type] IN ('Internal_Standard', 'contaminant', 'old_contaminant')
                          THEN 1
                          ELSE 0
                     END AS IntStandardOrContaminant,
                     Organism_Name,
                     Protein_Collection_ID As ID,
                     State_Name As State,
                     Includes_Contaminants,
                     Cast(File_Size_Bytes / 1024.0 / 1024 As Decimal(9,2)) As FileSizeMB
              FROM S_V_Protein_Collections_by_Organism
            ) AS CP
     ) AS LookupQ
     LEFT OUTER JOIN dbo.T_Organisms Org
       ON LookupQ.Organism_Name = Org.OG_Name
     LEFT OUTER JOIN T_Protein_Collection_Usage PCU
       ON LookupQ.ID = PCU.Protein_Collection_ID
GROUP BY LookupQ.ID, LookupQ.Name, LookupQ.Description, LookupQ.Organism_Name,
         LookupQ.State, LookupQ.Entries, LookupQ.Residues,
         PCU.Job_Usage_Count_Last12Months, PCU.Job_Usage_Count,
         PCU.Most_Recently_Used, LookupQ.Includes_Contaminants,
         LookupQ.FileSizeMB, LookupQ.[type], LookupQ.Source,
         LookupQ.IntStandardOrContaminant, Org.OG_organismDBName

GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_List_Report] TO [DDL_Viewer] AS [dbo]
GO
