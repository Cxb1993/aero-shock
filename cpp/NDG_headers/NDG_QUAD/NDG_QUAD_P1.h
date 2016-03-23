#ifndef NDG_QUAD_P1
#define NDG_QUAD_P1

int p = 1;

double r[4] = {-1,-1,1,1};

double s[4] = {-1,1,-1,1};

double Dr[4][4] = {{-0.5,0,0.5,0},
{0,-0.5,0,0.5},
{-0.5,0,0.5,0},
{0,-0.5,0,0.5}};

double Ds[4][4] = {{-0.5,0.5,0,0},
{-0.5,0.5,0,0},
{0,0,-0.5,0.5},
{0,0,-0.5,0.5}};

double LIFT[4][8] = {{2,-1,-1,0.5,-1,0.5,2,-1},
{-1,0.5,0.5,-1,2,-1,-1,2},
{-1,2,2,-1,0.5,-1,-1,0.5},
{0.5,-1,-1,2,-1,2,0.5,-1}};

double FaceMask[2][4] = {{0,2,1,0},
{2,3,3,1}};

double V[4][4] = {{0.5,-0.866025403784,-0.866025403784,1.5},
{0.5,0.866025403784,-0.866025403784,-1.5},
{0.5,-0.866025403784,0.866025403784,-1.5},
{0.5,0.866025403784,0.866025403784,1.5}};

#endif