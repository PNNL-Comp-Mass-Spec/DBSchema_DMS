/****** Object:  Table [dbo].[T_LC_Cart_Configuration] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart_Configuration](
	[Cart_Config_ID] [int] IDENTITY(100,1) NOT NULL,
	[Cart_Config_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Cart_ID] [int] NOT NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Autosampler] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Custom_Valve_Config] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Pumps] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Primary_Injection_Volume] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Primary_Mobile_Phases] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Primary_Trap_Column] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Primary_Trap_Flow_Rate] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Primary_Trap_Time] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Primary_Trap_Mobile_Phase] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Primary_Analytical_Column] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Primary_Column_Temperature] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Primary_Analytical_Flow_Rate] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Primary_Gradient] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mass_Spec_Start_Delay] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Upstream_Injection_Volume] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Upstream_Mobile_Phases] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Upstream_Trap_Column] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Upstream_Trap_Flow_Rate] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Upstream_Analytical_Column] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Upstream_Column_Temperature] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Upstream_Analytical_Flow_Rate] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Upstream_Fractionation_Profile] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Upstream_Fractionation_Details] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Cart_Config_State] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Entered] [datetime] NOT NULL,
	[Entered_By] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Updated] [datetime] NULL,
	[Updated_By] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_Usage_Count] [int] NULL,
	[Dataset_Usage_Last_Year] [int] NULL,
 CONSTRAINT [PK_T_LC_Cart_Configuration] PRIMARY KEY CLUSTERED 
(
	[Cart_Config_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_LC_Cart_Configuration] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_LC_Cart_Configuration] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_LC_Cart_Configuration] ON [dbo].[T_LC_Cart_Configuration]
(
	[Cart_Config_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_LC_Cart_Configuration_Cart_Id] ******/
CREATE NONCLUSTERED INDEX [IX_T_LC_Cart_Configuration_Cart_Id] ON [dbo].[T_LC_Cart_Configuration]
(
	[Cart_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration] ADD  CONSTRAINT [DF_T_LC_Cart_Configuration_Cart_Config_State]  DEFAULT ('Active') FOR [Cart_Config_State]
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration] ADD  CONSTRAINT [DF_T_LC_Cart_Configuration_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration] ADD  CONSTRAINT [DF_T_LC_Cart_Configuration_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Configuration_T_LC_Cart] FOREIGN KEY([Cart_ID])
REFERENCES [dbo].[T_LC_Cart] ([ID])
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration] CHECK CONSTRAINT [FK_T_LC_Cart_Configuration_T_LC_Cart]
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Configuration_T_Users_EnteredBy] FOREIGN KEY([Entered_By])
REFERENCES [dbo].[T_Users] ([U_PRN])
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration] CHECK CONSTRAINT [FK_T_LC_Cart_Configuration_T_Users_EnteredBy]
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Configuration_T_Users_UpdatedBy] FOREIGN KEY([Updated_By])
REFERENCES [dbo].[T_Users] ([U_PRN])
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration] CHECK CONSTRAINT [FK_T_LC_Cart_Configuration_T_Users_UpdatedBy]
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration]  WITH CHECK ADD  CONSTRAINT [CK_T_LC_Cart_Configuration_State] CHECK  (([Cart_Config_State]='Invalid' OR [Cart_Config_State]='Inactive' OR [Cart_Config_State]='Active'))
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration] CHECK CONSTRAINT [CK_T_LC_Cart_Configuration_State]
GO
