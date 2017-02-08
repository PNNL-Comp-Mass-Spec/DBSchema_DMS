/****** Object:  Table [dbo].[T_LC_Cart_Configuration] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart_Configuration](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Cart_ID] [int] NOT NULL,
	[Pumps] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Columns] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Traps] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mobile_Phase] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Injection] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Gradient] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NOT NULL,
	[Entered_By] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Updated] [datetime] NULL,
	[Updated_By] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_LC_Cart_Configuration] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_LC_Cart_Configuration] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_LC_Cart_Configuration] ADD  CONSTRAINT [DF_T_LC_Cart_Configuration_Entered]  DEFAULT (getdate()) FOR [Entered]
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
