--  Pure game logic: board, tetrominoes, SRS rotation, gravity, scoring.
--  No SDL types here so the rules can be tested headless.

with Interfaces; use Interfaces;

package Tetris_Game is
   Board_Width  : constant := 10;
   Board_Height : constant := 20;   --  visible rows
   Hidden_Rows  : constant := 4;    --  spawn buffer above the visible field
   Board_Rows   : constant := Board_Height + Hidden_Rows;

   Visible_First_Row : constant := Hidden_Rows + 1;

   --  Cell_States doubles as the list of piece kinds: a locked cell stores
   --  which tetromino it came from, which is exactly what rendering needs.
   type Cell_States is (Empty, I, O, T, S, Z, J, L);
   subtype Piece_Kinds is Cell_States range I .. L;

   type Board_Array is array (1 .. Board_Rows, 1 .. Board_Width) of Cell_States;

   type Rotations is mod 4;
   type Shape_Grid is array (0 .. 3, 0 .. 3) of Boolean;

   type Game_Status is (Playing, Game_Over);

   type Next_Queue_Array is array (1 .. 5) of Piece_Kinds;
   type Bag_Array is array (1 .. 7) of Piece_Kinds;

   Lock_Delay      : constant := 500;  --  ms a grounded piece stays movable
   Max_Lock_Resets : constant := 15;

   type Game is record
      Board            : Board_Array := (others => (others => Empty));
      Current          : Piece_Kinds := I;
      Rotation         : Rotations := 0;
      X, Y             : Integer := 1;
      Next_Queue       : Next_Queue_Array := (others => I);
      Hold_Kind        : Piece_Kinds := I;
      Has_Hold         : Boolean := False;
      Hold_Used        : Boolean := False;
      Score            : Natural := 0;
      Lines            : Natural := 0;
      Level            : Natural := 1;
      Status           : Game_Status := Playing;
      Drop_Accumulator : Natural := 0;
      Lock_Timer       : Natural := 0;
      Lock_Resets      : Natural := 0;
      Seed             : Unsigned_32 := 2_463_534_242;
      Bag              : Bag_Array := (others => I);
      Bag_Index        : Positive := 8;   --  forces a shuffle on first draw
      Last_Clear       : Natural := 0;    --  0 .. 4, for the banner
      Message_Timer    : Natural := 0;    --  ms the banner stays up
   end record;

   function Shape (Kind : Piece_Kinds; Rot : Rotations) return Shape_Grid;
   function Piece_Size (Kind : Piece_Kinds) return Positive;
   function Drop_Interval (Level : Natural) return Natural;

   procedure New_Game (G : out Game; Seed : Unsigned_32);

   --  Milliseconds of wall-clock time; handles gravity and lock delay.
   procedure Advance
     (G        : in out Game;
      Elapsed  : Natural;
      Soft_Drop : Boolean);

   procedure Move_Left (G : in out Game);
   procedure Move_Right (G : in out Game);
   procedure Rotate_CW (G : in out Game);
   procedure Rotate_CCW (G : in out Game);
   procedure Hard_Drop (G : in out Game);
   procedure Hold_Piece (G : in out Game);

   function Ghost_Y (G : Game) return Integer;
   function Cell (G : Game; Row, Col : Positive) return Cell_States;
end Tetris_Game;
