/****** Object:  Table [dbo].[T_OSM_Package] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_OSM_Package](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Package_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Keywords] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Owner] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
	[Last_Modified] [datetime] NOT NULL,
	[State] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Campaign_Item_Count] [int] NOT NULL,
	[Biomaterial_Item_Count] [int] NOT NULL,
	[Sample_Prep_Request_Item_Count] [int] NOT NULL,
	[Sample_Submission_Item_Count] [int] NOT NULL,
	[Material_Containers_Item_Count] [int] NOT NULL,
	[Experiment_Group_Item_Count] [int] NOT NULL,
	[Experiment_Item_Count] [int] NOT NULL,
	[HPLC_Runs_Item_Count] [int] NOT NULL,
	[Data_Packages_Item_Count] [int] NOT NULL,
	[Requested_Run_Item_Count] [int] NOT NULL,
	[Dataset_Item_Count] [int] NOT NULL,
	[Total_Item_Count] [int] NOT NULL,
	[Wiki_Page_Link] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_OSM_Package] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Packa__53D770D6]  DEFAULT ('General') FOR [Package_Type]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Descr__54CB950F]  DEFAULT ('') FOR [Description]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Comme__55BFB948]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Creat__56B3DD81]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF_T_OSM_Package_Last_Modified]  DEFAULT (getdate()) FOR [Last_Modified]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__State__57A801BA]  DEFAULT ('Active') FOR [State]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Campa__589C25F3]  DEFAULT ((0)) FOR [Campaign_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Bioma__59904A2C]  DEFAULT ((0)) FOR [Biomaterial_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Sampl__5A846E65]  DEFAULT ((0)) FOR [Sample_Prep_Request_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Sampl__5B78929E]  DEFAULT ((0)) FOR [Sample_Submission_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Mater__5C6CB6D7]  DEFAULT ((0)) FOR [Material_Containers_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Exper__5D60DB10]  DEFAULT ((0)) FOR [Experiment_Group_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Exper__5E54FF49]  DEFAULT ((0)) FOR [Experiment_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__HPLC___5F492382]  DEFAULT ((0)) FOR [HPLC_Runs_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Data___603D47BB]  DEFAULT ((0)) FOR [Data_Packages_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF_T_OSM_Package_Requested_Run_Item_Count]  DEFAULT ((0)) FOR [Requested_Run_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF_T_OSM_Package_Dataset_Item_Count]  DEFAULT ((0)) FOR [Dataset_Item_Count]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Total__61316BF4]  DEFAULT ((0)) FOR [Total_Item_Count]
GO
