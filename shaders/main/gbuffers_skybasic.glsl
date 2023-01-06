/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender Studios.

    Copyright (C) 2020 Eldeston


    By downloading this you have agreed to the license and terms of use.
    These can be found inside the included license-file.

    Violating these terms may be penalized with actions according to the Digital Millennium Copyright Act (DMCA),
    the Information Society Directive and/or similar laws depending on your country.

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