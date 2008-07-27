/****** Object:  Table [dbo].[T_LC_Cart_Component_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart_Component_History](
	[ID] [int] IDENTITY(10,1) NOT NULL,
	[Operator] [int] NOT NULL,
	[Action] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Starting_Date] [datetime] NOT NULL,
	[Ending_Date] [datetime] NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Cart_Component] [int] NOT NULL,
	[Component_Position] [int] NULL,
 CONSTRAINT [PK_T_LC_Cart_Component_History] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_LC_Cart_Component_History] ******/
CREATE NONCLUSTERED INDEX [IX_T_LC_Cart_Component_History] ON [dbo].[T_LC_Cart_Component_History] 
(
	[Cart_Component] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_LC_Cart_Component_History_1] ******/
CREATE NONCLUSTERED INDEX [IX_T_LC_Cart_Component_History_1] ON [dbo].[T_LC_Cart_Component_History] 
(
	[Component_Position] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_LC_Cart_Component_History]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Component_History_T_LC_Cart_Component_Postition] FOREIGN KEY([Component_Position])
REFERENCES [T_LC_Cart_Component_Postition] ([ID])
GO
ALTER TABLE [dbo].[T_LC_Cart_Component_History]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Component_History_T_LC_Cart_Components] FOREIGN KEY([Cart_Component])
REFERENCES [T_LC_Cart_Components] ([ID])
GO
ALTER TABLE [dbo].[T_LC_Cart_Component_History]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Component_History_T_Users] FOREIGN KEY([Operator])
REFERENCES [T_Users] ([ID])
GO
