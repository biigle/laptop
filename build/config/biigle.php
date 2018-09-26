<?php

return [

    /*
    | Version of the biigle/core build.
    */
   'version' => env('BIIGLE_VERSION'),

    /*
    | Show the logfiles in the admin area.
    */
   'admin_logs' => true,

   /*
   | Email address of the admins of this BIIGLE instance.
   */
   'admin_email' => env('ADMIN_EMAIL', ''),

   /*
   | Disable all features that require a working internet connection.
   */
   'offline_mode' => true,

   /*
   | Enable user registration. This allows everybody to create a new user account.
   */
   'user_registration' => true,

];
