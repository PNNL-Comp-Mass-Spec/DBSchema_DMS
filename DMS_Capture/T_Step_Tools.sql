/****** Object:  Table [dbo].[T_Step_Tools] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Step_Tools](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Bionet_Required] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Only_On_Storage_Server] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Instrument_Capacity_Limited] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Holdoff_Interval_Minutes] [smallint] NOT NULL,
	[Number_Of_Retries] [smallint] NOT NULL,
	[Processor_Assignment_Applies] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Step_Tools_1] PRIMARY KEY CLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_CPU_Load]  DEFAULT ('N') FOR [Bionet_Required]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Shared_Result]  DEFAULT ('N') FOR [Only_On_Storage_Server]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Instrument_Capacity_Limited]  DEFAULT ('N') FOR [Instrument_Capacity_Limited]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Holdoff_Interval]  DEFAULT ((0)) FOR [Holdoff_Interval_Minutes]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Number_Of_Retries]  DEFAULT ((0)) FOR [Number_Of_Retries]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Processor_Assignment_Applied]  DEFAULT ('N') FOR [Processor_Assignment_Applies]
GO
