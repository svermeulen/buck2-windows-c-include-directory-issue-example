#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT
#endif

DLLEXPORT int
lua_checkthing(lua_State *L)
{
    lua_pushboolean(L, 1);
    return 1;
}

DLLEXPORT int
luaopen_foo(lua_State *L)
{
    lua_newtable(L);
    lua_pushcfunction(L, lua_checkthing);
    lua_setfield(L, -2, "checkthing");

    return 1;
}
