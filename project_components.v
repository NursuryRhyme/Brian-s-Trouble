`define SCREEN_W 8'd160
`define SCREEN_H 7'd120
`define PLAYER_WIDTH 2'd3

module player_control(
    input left,
    input right,
    input play,
    input load_level,
    input resetn,
    input clk,
    output reg move,
    output reg [7:0] playerX, // x and y for top left pixel of player
    output reg [6:0] playerY
    );
    
    localparam RATE_DIV = 28'd500000; // lower to move faster
    localparam START_X = 8'd80, START_Y = 7'd115;
    reg [27:0] counter;
    
    initial begin
        playerX <= START_X;
        playerY <= START_Y;
    end
    
    always@(posedge clk) begin
        if (!resetn || load_level) begin
            counter <= 0;
            move <= 0;
            playerX <= START_X;
            playerY <= START_Y;
        end
        
        if (play) begin     // control player through inputs
            if (left) begin
                if (counter == RATE_DIV) begin
                    if (playerX > 0)
                        playerX <= playerX - 1;
                    move <= 1;
                    counter <= 0;
                end
                else begin
                    counter <= counter + 1;
                    move <= 0;
                end
            end
            else if (right) begin
                if (counter == RATE_DIV) begin
                    if ((playerX + `PLAYER_WIDTH - 1) < `SCREEN_W)
                        playerX <= playerX + 1;
                    move <= 1;
                    counter <= 0;
                end
                else begin
                    counter <= counter + 1;
                    move <= 0;
                end
            end
            else begin
                move <= 0;
                counter <= 0;
            end
        end
    end
endmodule

module enemy_control(
    input [3:0] width, // width of square enemy in pixels
    input [27:0] rate_div, // lower to move faster
    input [7:0] start_x,
    input [6:0] start_y,
    input [2:0] d_x, // slope d_y/d_x
    input [2:0] d_y,
    input leftwards, // direction of enemy when spawned
    input upwards,
    input [7:0] playerX,
    input [6:0] playerY,
    input [7:0] bulletX,
    input [6:0] bulletY,
    input enable,
    input load_level,
    input play,
    input resetn,
    input clk,
    output player_hit, // player collision
    output bullet_hit,
    output [3:0] enemy_width,
    output reg move,
    output reg [7:0] enemyX, // coordinates for the top left pixel of the enemy
    output reg [6:0] enemyY,
    output reg alive
    );
    
    reg [27:0] counter;
    reg left, up;
    
    always@(posedge clk) begin
        if (!resetn || load_level) begin
            enemyX <= start_x;
            enemyY <= start_y;
            counter <= 0;
            left <= leftwards;
            up <= upwards;
            move <= 0;
            alive <= enable;
        end
        if (play && alive) begin
            if (counter == rate_div) begin
                if (left) begin
                    if (enemyX <= d_x) begin // hit left edge, change directions
                        enemyX <= 0;
                        left <= 0;
                    end else begin
                        enemyX <= enemyX - d_x;
                    end
                end else begin
                    if (enemyX + width - 1 >= `SCREEN_W - d_x) begin // hit right edge
                        enemyX <= `SCREEN_W - width + 1;
                        left <= 1;
                    end else begin
                        enemyX <= enemyX + d_x;
                    end
                end
                if (up) begin
                    if (enemyY <= d_y) begin // hit top edge
                        enemyY <= 0;
                        up <= 0;
                    end else begin
                        enemyY <= enemyY - d_y;
                    end
                end else begin
                    if (enemyY + width - 1 >= `SCREEN_H - d_y) begin // hit bottom edge
                        enemyY <= `SCREEN_H - width + 1;
                        up <= 1;
                    end else begin
                        enemyY <= enemyY + d_y;
                    end
                end
                counter <= 0;
                move <= 1;
            end else begin
                counter <= counter + 1;
                move <= 0;
            end
        end
        if (bullet_hit) begin
            alive <= 0;
        end
    end
    
    // collision with player
    assign player_hit = alive && ((playerX <= (enemyX + enemy_width - 1) && enemyX <= (playerX + `PLAYER_WIDTH - 1))
        && (playerY <= (enemyY + enemy_width - 1) && enemyY <= (playerY + `PLAYER_WIDTH - 1)));
        
    // collision with bullet
    assign bullet_hit = alive && ((bulletX <= (enemyX + enemy_width - 1) && enemyX <= bulletX)
        && (bulletY <= (enemyY + enemy_width - 1) && enemyY <= bulletY));
     
    assign enemy_width = alive ? width : 0;
endmodule

module bullet_control(
    input fire,
    input [7:0] playerX,
    input [6:0] playerY,
    input bullet_hit,
    input play,
    input load_level,
    input resetn,
    input clk,
    output reg move,
    output reg [7:0] bulletX,
    output reg [6:0] bulletY
    );

    localparam RATE_DIV = 28'd500000; // lower to move faster
    reg [27:0] counter;
    reg fired;
    
    initial begin
         fired <= 0;     
    end
    
    always@(posedge clk) begin
        move <= 0; // default
        if (!resetn || load_level) begin
            fired <= 0;
            bulletX <= playerX + 1;
            bulletY <= playerY + 1;
            counter <= 0;
        end
        if (play) begin
            if (fire && !fired) begin
                fired <= 1;
                bulletX <= playerX + 1;
                bulletY <= playerY;
                counter <= 0;
            end else if (fired) begin
                if (bulletY <= 0) begin
                    fired <= 0;
                    counter <= 0;
                    bulletX <= playerX + 1;
                    bulletY <= playerY + 1;
                end else if (counter == RATE_DIV) begin
                    bulletY <= bulletY - 1;
                    counter <= 0;
                    move <= 1;
                end else begin
                    counter <= counter + 1;
                end
            end else if (!fired) begin
                bulletX <= playerX + 1;
                bulletY <= playerY + 1;
            end
            
            if (bullet_hit) begin
                fired <= 0;
                bulletX <= playerX + 1;
                bulletY <= playerY + 1;
                counter <= 0;
            end
        end
    end
endmodule
