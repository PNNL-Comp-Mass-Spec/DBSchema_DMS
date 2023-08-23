/****** Object:  View [dbo].[V_Event_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Event_Log 
AS
SELECT EL.event_id,
       EL.target_type,
       CASE EL.target_type
           WHEN 1 THEN 'Protein Collection'
           ELSE NULL
       END AS target,
       EL.target_id,
       EL.target_state,
       CASE
           WHEN EL.target_type = 1 THEN 
                    CASE WHEN EL.target_state = 0 AND
                              EL.prev_target_state > 0 
                         THEN 'Deleted'
                         ELSE PCS.state
                    END
           ELSE NULL
       END AS state_name,
       EL.prev_target_state,
       EL.entered,
       EL.entered_by
FROM T_Event_Log EL
     LEFT OUTER JOIN T_Protein_Collection_States PCS
       ON EL.target_state = PCS.collection_state_id AND
          EL.target_type = 1

GO
