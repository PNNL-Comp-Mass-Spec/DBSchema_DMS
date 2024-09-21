/****** Object:  View [dbo].[V_Spectral_Library_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Spectral_Library_List_Report 
AS
SELECT sl.library_id,
       sl.library_name,
       sl.created,
       sl.source_job,
       sl.comment,
       sl.storage_path,
       libstate.library_state,
       sl.protein_collection_list,
       sl.organism_db_file,
       sl.dynamic_mods,
       sl.max_dynamic_mods,
       sl.static_cys_carbamidomethyl,
       sl.static_mods,
       sl.fragment_ion_mz_min,
       sl.fragment_ion_mz_max,
       sl.trim_n_terminal_met,
       sl.cleavage_specificity,
       sl.missed_cleavages,
       sl.peptide_length_min,
       sl.peptide_length_max,
       sl.precursor_mz_min,
       sl.precursor_mz_max,
       sl.precursor_charge_min,
       sl.precursor_charge_max,
       sl.program_version,
       sl.settings_hash,
       sl.completion_code,
       sl.last_affected,
       libtype.library_type,
       libtype.description AS library_type_description
FROM dbo.t_spectral_library sl
     INNER JOIN dbo.t_spectral_library_state libstate
       ON sl.library_state_id = libstate.library_state_id
     INNER JOIN dbo.t_spectral_library_type libtype
       ON sl.library_type_id = libtype.library_type_id
WHERE NOT sl.library_state_id IN (4, 5)

GO
