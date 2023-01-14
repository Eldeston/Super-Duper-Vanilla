/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Completely disable this program

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    void main(){
        gl_Position = vec4(-10);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    void main(){
        discard;
    }
#endif