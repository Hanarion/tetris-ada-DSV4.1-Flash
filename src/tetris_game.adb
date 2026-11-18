with Interfaces; use Interfaces;

package body Tetris_Game is

   function Piece_Size (Kind : Piece_Kinds) return Positive is
     (case Kind is
        when I        => 4,
        when O        => 2,
        when T | S | Z | J | L => 3);

   ---------------------------------------------------------------------------
   --  Rotations are stored 0 .. 3 for every tetromino (O included, harmlessly).
   ---------------------------------------------------------------------------

   type Shape_Table is array (Piece_Kinds, Rotations) of Shape_Grid;

   function Rotated (S : Shape_Grid; N : Positive) return Shape_Grid is
      Result : Shape_Grid := (others => (others => False));
   begin
      for Row in 0 .. N - 1 loop
         for Col in 0 .. N - 1 loop
            Result (Row, Col) := S (N - 1 - Col, Row);
         end loop;
      end loop;
      return Result;
   end Rotated;

   function Base_Shape (Kind : Piece_Kinds) return Shape_Grid is
      Grid : Shape_Grid := (others => (others => False));
   begin
      case Kind is
         when I =>
            for Col in 0 .. 3 loop
               Grid (1, Col) := True;
            end loop;
         when O =>
            Grid (0, 0) := True;  Grid (0, 1) := True;
            Grid (1, 0) := True;  Grid (1, 1) := True;
         when T =>
            Grid (0, 1) := True;
            Grid (1, 0) := True;  Grid (1, 1) := True;  Grid (1, 2) := True;
         when S =>
            Grid (0, 1) := True;  Grid (0, 2) := True;
            Grid (1, 0) := True;  Grid (1, 1) := True;
         when Z =>
            Grid (0, 0) := True;  Grid (0, 1) := True;
            Grid (1, 1) := True;  Grid (1, 2) := True;
         when J =>
            Grid (0, 0) := True;
            Grid (1, 0) := True;  Grid (1, 1) := True;  Grid (1, 2) := True;
         when L =>
            Grid (0, 2) := True;
            Grid (1, 0) := True;  Grid (1, 1) := True;  Grid (1, 2) := True;
      end case;
      return Grid;
   end Base_Shape;

   function Build_Shapes return Shape_Table is
      Result : Shape_Table;
   begin
      for Kind in Piece_Kinds loop
         declare
            Base : Shape_Grid := Base_Shape (Kind);
         begin
            Result (Kind, 0) := Base;
            for Turn in 1 .. 3 loop
               Base := Rotated (Base, Piece_Size (Kind));
               Result (Kind, Rotations (Turn)) := Base;
            end loop;
         end;
      end loop;
      return Result;
   end Build_Shapes;

   Shapes : constant Shape_Table := Build_Shapes;

   function Shape (Kind : Piece_Kinds; Rot : Rotations) return Shape_Grid is
     (Shapes (Kind, Rot));

   ---------------------------------------------------------------------------
   --  Collision.
   ---------------------------------------------------------------------------

   function Collides
     (G    : Game;
      Kind : Piece_Kinds;
      Rot  : Rotations;
      X, Y : Integer) return Boolean
   is
      S : constant Shape_Grid := Shape (Kind, Rot);
      N : constant Positive   := Piece_Size (Kind);
   begin
      for R in 0 .. N - 1 loop
         for C in 0 .. N - 1 loop
            if S (R, C) then
               declare
                  Row : constant Integer := Y + R;
                  Col : constant Integer := X + C;
               begin
                  if Col < 1 or else Col > Board_Width
                    or else Row < 1 or else Row > Board_Rows
                  then
                     return True;
                  end if;
                  if G.Board (Row, Col) /= Empty then
                     return True;
                  end if;
               end;
            end if;
         end loop;
      end loop;
      return False;
   end Collides;

   function Grounded (G : Game) return Boolean is
     (Collides (G, G.Current, G.Rotation, G.X, G.Y + 1));

   procedure Touch_Lock (G : in out Game) is
   begin
      if G.Lock_Resets < Max_Lock_Resets and then Grounded (G) then
         G.Lock_Timer  := 0;
         G.Lock_Resets := G.Lock_Resets + 1;
      end if;
   end Touch_Lock;

   ---------------------------------------------------------------------------
   --  SRS wall kicks.  Offsets are (x right, y up); rows are applied negated.
   ---------------------------------------------------------------------------

   type Kick_Offset is record
      DX : Integer := 0;
      DY : Integer := 0;
   end record;

   type Kick_List is array (1 .. 5) of Kick_Offset;

   function Kicks_For
     (Kind : Piece_Kinds;
      From : Rotations;
      To   : Rotations) return Kick_List
   is
   begin
      if Kind = O then
         return (others => (0, 0));
      end if;

      if Kind = I then
         case From is
            when 0 =>
               if To = 1 then
                  return ((0, 0), (-2, 0), (1, 0), (-2, -1), (1, 2));
               else
                  return ((0, 0), (-1, 0), (2, 0), (-1, 2), (2, -1));
               end if;
            when 1 =>
               if To = 0 then
                  return ((0, 0), (2, 0), (-1, 0), (2, 1), (-1, -2));
               else
                  return ((0, 0), (-1, 0), (2, 0), (-1, 2), (2, -1));
               end if;
            when 2 =>
               if To = 1 then
                  return ((0, 0), (1, 0), (-2, 0), (1, -2), (-2, 1));
               else
                  return ((0, 0), (2, 0), (-1, 0), (2, 1), (-1, -2));
               end if;
            when 3 =>
               if To = 2 then
                  return ((0, 0), (-2, 0), (1, 0), (-2, -1), (1, 2));
               else
                  return ((0, 0), (1, 0), (-2, 0), (1, -2), (-2, 1));
               end if;
         end case;
      end if;

      case From is
         when 0 =>
            if To = 1 then
               return ((0, 0), (-1, 0), (-1, 1), (0, -2), (-1, -2));
            else
               return ((0, 0), (1, 0), (1, 1), (0, -2), (1, -2));
            end if;
         when 1 =>
            if To = 0 then
               return ((0, 0), (1, 0), (1, -1), (0, 2), (1, 2));
            else
               return ((0, 0), (1, 0), (1, -1), (0, 2), (1, 2));
            end if;
         when 2 =>
            if To = 1 then
               return ((0, 0), (-1, 0), (-1, 1), (0, -2), (-1, -2));
            else
               return ((0, 0), (1, 0), (1, 1), (0, -2), (1, -2));
            end if;
         when 3 =>
            if To = 2 then
               return ((0, 0), (-1, 0), (-1, -1), (0, 2), (-1, 2));
            else
               return ((0, 0), (-1, 0), (-1, -1), (0, 2), (-1, 2));
            end if;
      end case;
   end Kicks_For;

   procedure Do_Rotate (G : in out Game; Clockwise : Boolean) is
      New_Rot : constant Rotations :=
        (if Clockwise then G.Rotation + 1 else G.Rotation - 1);
   begin
      if G.Status /= Playing then
         return;
      end if;

      for Test in 1 .. 5 loop
         declare
            K : constant Kick_Offset := Kicks_For (G.Current, G.Rotation, New_Rot) (Test);
         begin
            if not Collides (G, G.Current, New_Rot, G.X + K.DX, G.Y - K.DY) then
               G.Rotation := New_Rot;
               G.X        := G.X + K.DX;
               G.Y        := G.Y - K.DY;
               Touch_Lock (G);
               return;
            end if;
         end;
      end loop;
   end Do_Rotate;

   procedure Rotate_CW (G : in out Game) is
   begin
      Do_Rotate (G, True);
   end Rotate_CW;

   procedure Rotate_CCW (G : in out Game) is
   begin
      Do_Rotate (G, False);
   end Rotate_CCW;

   ---------------------------------------------------------------------------
   --  Movement.
   ---------------------------------------------------------------------------

   procedure Move_Left (G : in out Game) is
   begin
      if G.Status = Playing
        and then not Collides (G, G.Current, G.Rotation, G.X - 1, G.Y)
      then
         G.X := G.X - 1;
         Touch_Lock (G);
      end if;
   end Move_Left;

   procedure Move_Right (G : in out Game) is
   begin
      if G.Status = Playing
        and then not Collides (G, G.Current, G.Rotation, G.X + 1, G.Y)
      then
         G.X := G.X + 1;
         Touch_Lock (G);
      end if;
   end Move_Right;

   ---------------------------------------------------------------------------
   --  Randomizer: 7-bag, xorshift32.
   ---------------------------------------------------------------------------

   function Next_Random (G : in out Game) return Unsigned_32 is
      S : Unsigned_32 := G.Seed;
   begin
      if S = 0 then
         S := 2_463_534_242;
      end if;
      S := S xor Shift_Left (S, 13);
      S := S xor Shift_Right (S, 17);
      S := S xor Shift_Left (S, 5);
      G.Seed := S;
      return S;
   end Next_Random;

   procedure Shuffle_Bag (G : in out Game) is
      J   : Natural;
      Tmp : Piece_Kinds;
   begin
      for Idx in 1 .. 7 loop
         G.Bag (Idx) := Piece_Kinds'Val (Idx);
      end loop;
      for Idx in reverse 2 .. 7 loop
         J := 1 + Natural (Next_Random (G) mod Unsigned_32 (Idx));
         Tmp := G.Bag (Idx);
         G.Bag (Idx) := G.Bag (J);
         G.Bag (J) := Tmp;
      end loop;
      G.Bag_Index := 1;
   end Shuffle_Bag;

   function Draw_From_Bag (G : in out Game) return Piece_Kinds is
      Result : Piece_Kinds;
   begin
      if G.Bag_Index > 7 then
         Shuffle_Bag (G);
      end if;
      Result := G.Bag (G.Bag_Index);
      G.Bag_Index := G.Bag_Index + 1;
      return Result;
   end Draw_From_Bag;

   function Take_Next (G : in out Game) return Piece_Kinds is
      Result : constant Piece_Kinds := G.Next_Queue (1);
   begin
      for Idx in 1 .. G.Next_Queue'Last - 1 loop
         G.Next_Queue (Idx) := G.Next_Queue (Idx + 1);
      end loop;
      G.Next_Queue (G.Next_Queue'Last) := Draw_From_Bag (G);
      return Result;
   end Take_Next;

   procedure Spawn (G : in out Game; Kind : Piece_Kinds) is
   begin
      G.Current      := Kind;
      G.Rotation     := 0;
      G.X            := (if Kind = O then 5 else 4);
      G.Y            := 1;
      G.Drop_Accumulator := 0;
      G.Lock_Timer   := 0;
      G.Lock_Resets  := 0;

      if Collides (G, Kind, 0, G.X, G.Y) then
         G.Status := Game_Over;
      end if;
   end Spawn;

   ---------------------------------------------------------------------------
   --  Line clears and scoring.
   ---------------------------------------------------------------------------

   function Row_Full (G : Game; Row : Positive) return Boolean is
   begin
      for Col in 1 .. Board_Width loop
         if G.Board (Row, Col) = Empty then
            return False;
         end if;
      end loop;
      return True;
   end Row_Full;

   procedure Clear_Lines (G : in out Game) is
      Count  : Natural := 0;
      Target : Integer;
   begin
      for Row in 1 .. Board_Rows loop
         if Row_Full (G, Row) then
            Count := Count + 1;
         end if;
      end loop;

      if Count = 0 then
         return;
      end if;

      Target := Board_Rows;
      for Row in reverse 1 .. Board_Rows loop
         if not Row_Full (G, Row) then
            if Target /= Row then
               for Col in 1 .. Board_Width loop
                  G.Board (Target, Col) := G.Board (Row, Col);
               end loop;
            end if;
            Target := Target - 1;
         end if;
      end loop;

      for Row in 1 .. Target loop
         for Col in 1 .. Board_Width loop
            G.Board (Row, Col) := Empty;
         end loop;
      end loop;

      case Count is
         when 1      => G.Score := G.Score + 100 * G.Level;
         when 2      => G.Score := G.Score + 300 * G.Level;
         when 3      => G.Score := G.Score + 500 * G.Level;
         when others => G.Score := G.Score + 800 * G.Level;
      end case;

      G.Lines    := G.Lines + Count;
      G.Level    := 1 + G.Lines / 10;
      G.Last_Clear  := Count;
      G.Message_Timer := 900;
   end Clear_Lines;

   procedure Lock_Piece (G : in out Game) is
      S : constant Shape_Grid := Shape (G.Current, G.Rotation);
      N : constant Positive   := Piece_Size (G.Current);
   begin
      for R in 0 .. N - 1 loop
         for C in 0 .. N - 1 loop
            if S (R, C) then
               G.Board (G.Y + R, G.X + C) := Cell_States (G.Current);
            end if;
         end loop;
      end loop;

      Clear_Lines (G);
      G.Hold_Used    := False;
      Spawn (G, Take_Next (G));
   end Lock_Piece;

   procedure Hard_Drop (G : in out Game) is
      Rows : Natural := 0;
   begin
      if G.Status /= Playing then
         return;
      end if;

      while not Collides (G, G.Current, G.Rotation, G.X, G.Y + 1) loop
         G.Y := G.Y + 1;
         Rows := Rows + 1;
      end loop;

      G.Score := G.Score + 2 * Rows;
      Lock_Piece (G);
   end Hard_Drop;

   procedure Hold_Piece (G : in out Game) is
      New_Kind : Piece_Kinds;
   begin
      if G.Status /= Playing or else G.Hold_Used then
         return;
      end if;

      if G.Has_Hold then
         New_Kind    := G.Hold_Kind;
         G.Hold_Kind := G.Current;
      else
         New_Kind    := Take_Next (G);
         G.Hold_Kind := G.Current;
         G.Has_Hold  := True;
      end if;

      G.Hold_Used := True;
      Spawn (G, New_Kind);
   end Hold_Piece;

   ---------------------------------------------------------------------------
   --  Public queries.
   ---------------------------------------------------------------------------

   function Ghost_Y (G : Game) return Integer is
      Y : Integer := G.Y;
   begin
      while not Collides (G, G.Current, G.Rotation, G.X, Y + 1) loop
         Y := Y + 1;
      end loop;
      return Y;
   end Ghost_Y;

   function Cell (G : Game; Row, Col : Positive) return Cell_States is
     (G.Board (Row, Col));

   function Drop_Interval (Level : Natural) return Natural is
      Table : constant array (1 .. 20) of Natural :=
        (800, 720, 630, 550, 470, 380, 300, 220, 160, 120,
         100,  85,  70,  60,  50,  45,  40,  35,  30,  25);
   begin
      return Table (Natural'Min (Natural'Max (Level, 1), 20));
   end Drop_Interval;

   ---------------------------------------------------------------------------
   --  Game lifecycle and time step.
   ---------------------------------------------------------------------------

   procedure New_Game (G : out Game; Seed : Unsigned_32) is
   begin
      G.Board            := (others => (others => Empty));
      G.Current          := I;
      G.Rotation         := 0;
      G.X                := 1;
      G.Y                := 1;
      G.Hold_Kind        := I;
      G.Has_Hold         := False;
      G.Hold_Used        := False;
      G.Score            := 0;
      G.Lines            := 0;
      G.Level            := 1;
      G.Status           := Playing;
      G.Drop_Accumulator := 0;
      G.Lock_Timer       := 0;
      G.Lock_Resets      := 0;
      G.Seed             := (if Seed = 0 then 2_463_534_242 else Seed);
      G.Bag_Index        := 8;
      G.Last_Clear       := 0;
      G.Message_Timer    := 0;

      Shuffle_Bag (G);
      for Idx in G.Next_Queue'Range loop
         G.Next_Queue (Idx) := Draw_From_Bag (G);
      end loop;

      Spawn (G, Take_Next (G));
   end New_Game;

   procedure Advance
     (G        : in out Game;
      Elapsed  : Natural;
      Soft_Drop : Boolean)
   is
      Interval : Natural;
   begin
      if G.Status /= Playing then
         return;
      end if;

      if G.Message_Timer > 0 then
         G.Message_Timer :=
           (if Elapsed >= G.Message_Timer then 0 else G.Message_Timer - Elapsed);
      end if;

      if Grounded (G) then
         G.Drop_Accumulator := 0;
         G.Lock_Timer := G.Lock_Timer + Elapsed;
         if G.Lock_Timer >= Lock_Delay then
            Lock_Piece (G);
         end if;
         return;
      end if;

      G.Lock_Timer := 0;
      Interval := (if Soft_Drop
                   then Natural'Min (40, Drop_Interval (G.Level))
                   else Drop_Interval (G.Level));
      G.Drop_Accumulator := G.Drop_Accumulator + Elapsed;

      while G.Drop_Accumulator >= Interval and then G.Status = Playing loop
         G.Drop_Accumulator := G.Drop_Accumulator - Interval;
         exit when Collides (G, G.Current, G.Rotation, G.X, G.Y + 1);
         G.Y := G.Y + 1;
         if Soft_Drop then
            G.Score := G.Score + 1;
         end if;
      end loop;
   end Advance;

end Tetris_Game;
