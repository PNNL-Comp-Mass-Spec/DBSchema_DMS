/****** Object:  View [dbo].[V_Active_Requested_Runs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Active_Requested_Runs]
AS
SELECT request,
       name,
       status,
       origin,
       acq_start,
       batch,
       campaign,
       experiment,
       dataset,
       instrument,
       inst_group,
       requester,
       created,
       days_in_queue,
       queue_state,
       queued_instrument,
       work_package,
       wp_state,
       usage,
       proposal,
       proposal_type,
       proposal_state,
       comment,
       type,
       separation_group,
       wellplate,
       well,
       vialing_conc,
       vialing_vol,
       staging_location,
       block,
       run_order,
       cart,
       cart_config,
       dataset_comment,
       request_name_code,
       days_in_queue_bin,
       wp_activation_state
FROM V_Requested_Run_List_Report_2
WHERE Status = 'Active'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Active_Requested_Runs] TO [DDL_Viewer] AS [dbo]
GO
