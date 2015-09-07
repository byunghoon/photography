//
//  GPUImageMedianBlendingFilter.m
//  Photography
//
//  Created by Byunghoon Yoon on 2015-09-06.
//  Copyright © 2015 Byunghoon. All rights reserved.
//

#import "GPUImageMedianBlendingFilter.h"

NSString *const kMedianBlendingFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 
 void main()
 {
     lowp vec3 va = texture2D(inputImageTexture, textureCoordinate).rgb;
     lowp vec3 vb = texture2D(inputImageTexture2, textureCoordinate2).rgb;
     lowp vec3 vc = texture2D(inputImageTexture3, textureCoordinate3).rgb;
     
     int mx = max(max(va, vb), vc);
     int mn = min(min(va, vb), vc);
     int md = va ^ vb ^ vc ^ mx ^ mn;
     
     gl_FragColor = vec4(md, 1.0);
 }
);

@implementation GPUImageMedianBlendingFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kMedianBlendingFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end
